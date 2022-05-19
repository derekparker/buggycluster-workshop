.PHONY: debug
debug:
	dlv debug

.PHONY: build
build:
	go build -gcflags="all=-N -l" -o bin/prog

.PHONY: copy-dlv
copy-dlv:
	cp $$(which dlv) ./bin

.PHONY: start-vm
start-vm:
	vagrant up

.PHONY: destroy-vm
destroy-vm:
	vagrant destroy

.PHONY: ssh-to-vm
ssh-to-vm:
	vagrant ssh

.PHONY: connect-to-remote
connect-to-remote:
	dlv connect :4040

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
	docker run -it --detach -p 8081:8081 --rm $(BASIC_IMG)

.PHONY: curl-app
curl-app:
	curl localhost:8081/foo/bar

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

.PHONY: reset-ptrace-yama
reset-ptrace-yama:
	echo "1" | sudo tee /proc/sys/kernel/yama/ptrace_scope

# Run basic image with ptrace SYS_CAP.
.PHONY: run-basic-image-with-ptrace
run-basic-image-with-ptrace:
	docker run -it --detach --rm -p 8081:8081 --cap-add=SYS_PTRACE $(BASIC_IMG)

# Exec dlv within basic container, using substitute path config.
.PHONY: exec-dlv-basic-container-with-src
exec-dlv-basic-container-with-src:
	docker cp $$(pwd) $$(docker ps -aqf "ancestor=$(BASIC_IMG)"):/src
	docker cp /usr/lib/go-1.17 $$(docker ps -aqf "ancestor=$(BASIC_IMG)"):/goroot
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
	docker run -it --detach -p 8081:8081 --name=buggy-scratch --rm $(SCRATCH_IMG)

# Debug scratch image.
.PHONY: debug-scratch-image
debug-scratch-image:
	docker run -it --rm --cap-add=SYS_PTRACE --pid="container:buggy-scratch" buggy-debug /bin/bash

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

# Connect to headless dlv server within container.
.PHONY: connect-to-remote-dlv
connect-to-remote-dlv:
	dlv connect localhost:9090
