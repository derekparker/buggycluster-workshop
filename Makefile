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

