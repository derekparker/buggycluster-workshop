###################
## HOST commands ##
###################

.PHONY: run
run:
	go run main.go

.PHONY: curl-app
curl-app:
	curl localhost:8080/foo/bar

.PHONY: install-delve
install-delve:
	go install github.com/go-delve/delve/cmd/dlv@latest

.PHONY: debug
debug:
	dlv debug

.PHONY: build
build:
	go build -gcflags="all=-N -l" -o bin/app

.PHONY: clean
clean:
	rm -rf bin

.PHONY: dlv-exec
dlv-exec:
	dlv exec bin/app

##############################
## Container Image commands ##
##############################

BASIC_IMG := buggy-basic
SCRATCH_IMG := buggy-scratch
DELVE_IMG := buggy-with-delve

# Build basic container image.
.PHONY: build-image
build-image:
	docker build --pull --rm -f build/Dockerfile-basic -t $(BASIC_IMG):latest .

.PHONY: run-basic-image
run-basic-image:
	docker run -it --detach -p 8080:8080 --rm $(BASIC_IMG)

# Copy dlv binary into basic container.
.PHONY: copy-dlv-to-container
copy-dlv-to-container:
	docker cp $$(which dlv) $$(docker ps -aqf "ancestor=$(BASIC_IMG)"):/dlv

# Exec dlv within basic container.
.PHONY: exec-dlv-basic-container
exec-dlv-basic-container:
	docker exec -it $$(docker ps -aqf "ancestor=$(BASIC_IMG)") /dlv attach 1

.PHONY: change-ptrace-yama
change-ptrace-yama:
	echo "0" | sudo tee /proc/sys/kernel/yama/ptrace_scope

# Run basic image with ptrace SYS_CAP.
.PHONY: run-basic-image-with-ptrace
run-basic-image-with-ptrace:
	docker run -it --detach --rm -p 8080:8080 --cap-add=SYS_PTRACE $(BASIC_IMG)

# Exec dlv within basic container, using substitute path config.
.PHONY: exec-dlv-basic-container-with-src
exec-dlv-basic-container-with-src:
	docker cp $$(pwd) $$(docker ps -aqf "ancestor=$(BASIC_IMG)"):/src
	docker cp /usr/local/go $$(docker ps -aqf "ancestor=$(BASIC_IMG)"):/goroot
	docker exec -it $$(docker ps -aqf "ancestor=$(BASIC_IMG)") /dlv --init=/src/hack/delve-container-initfile attach 1

.PHONY: build-scratch-image
build-scratch-image:
	docker build --pull --rm -f build/Dockerfile-scratch -t $(SCRATCH_IMG):latest .

.PHONY: build-debug-image
build-debug-image:
	docker build --pull --rm -f build/Dockerfile-debug -t buggy-debug:latest .

# Run scratch image.
.PHONY: run-scratch-image
run-scratch-image:
	docker run -it --detach -p 8080:8080 --name=buggy-scratch --rm $(SCRATCH_IMG)

# Debug scratch image.
.PHONY: debug-scratch-image
debug-scratch-image:
	docker run -it --rm --pid="container:buggy-scratch" buggy-debug /bin/bash

# Build docker image containing Delve binary already.
.PHONY: build-image-with-delve
build-image-with-delve:
	docker build --pull --rm -f build/Dockerfile-with-delve -t $(DELVE_IMG):latest .

# Run docker image containing delve binary.
.PHONY: run-dlv-container
run-dlv-container:
	docker run --cap-add=SYS_PTRACE --rm -it --detach -p 8080:8080 -p 9090:9090 $(DELVE_IMG)

# Connect to headless dlv server within container.
.PHONY: connect-to-remote-dlv
connect-to-remote-dlv:
	dlv connect localhost:9090

#########################
## Kubernetes commands ##
#########################

POD := $$(kubectl get pods -o name | head -n 1 | sed 's/pod\///g')
DLV_POD := $$(kubectl get pods -o name | grep dlv | head -n 1 | sed 's/pod\///g')
KIND_CLUSTER := buggycluster

.PHONY: install-kind
install-kind:
	go install sigs.k8s.io/kind@v0.11.1

.PHONY: devinstall-osx
devinstall-osx:
	brew install kubectl

.PHONY: devinstall-linux
devinstall-linux:
	snap install kubectl --classic

.PHONY: create-cluster
create-cluster:
	kind create cluster --name=$(KIND_CLUSTER)

.PHONY: deploy-service
deploy-service:
	kubectl create -f ./deploy/service-basic.yaml

.PHONY: copy-delve-to-pod
copy-delve-to-pod:
	kubectl cp $$(which dlv) $(POD):/dlv

.PHONY: exec-into-pod
exec-into-pod:
	kubectl exec -i -t $(POD) /bin/bash

.PHONY: redeploy-service
redeploy-service:
	kubectl apply -f ./deploy/service-basic-ptrace.yaml

.PHONY: deploy-dlv-service
deploy-dlv-service:
	kubectl apply -f ./deploy/service-with-dlv.yaml

.PHONY: port-forward
port-forward:
	kubectl port-forward $(DLV_POD) 9090:9090

.PHONY: kube-debug
kube-debug:
	kubectl debug -it $(POD) --image=derekparker/dlv-service --share-processes --copy-to=debug-pod -- /bin/sh

.PHONY: cleanup-debug-pod
cleanup-debug-pod:
	kubectl delete pod debug-pod

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster --name=$(KIND_CLUSTER)
