.PHONY: vagrant-up
vagrant-up:
	vagrant up

.PHONY: vagrant-destroy
vagrant-destroy:
	vagrant destroy

.PHONY: vagrant-ssh
vagrant-ssh:
	vagrant ssh

###################
## HOST commands ##
###################

.PHONY: run
run:
	go run main.go

.PHONY: curl-app
curl-app:
	curl localhost:8080/foo/bar

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
