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
