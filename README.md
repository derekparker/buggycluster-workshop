# Bugs on a Cluster!

This repo contains the intitial code for the Bugs on a Cluster mini-workshop and also acts as the
main repository for students / attendees to pull the code as the workshop progresses so they can follow along.

# Prerequisites

* Go toolchain
* Docker (or PodMan)
* Kubectl
* Kind

## Cloning repo

```
git clone -b jaxgo https://github.com/derekparker/buggycluster-workshop.git
```

## Talk description

You are tasked with creating a cloud native application which can run in a container and also be deployed
within a kubernetes cluster.

Easy enough, right? Wrong!

Unfortunately bugs abound and have infected the cluster. It is up to you, our intrepid developer to
clear out all the bugs and get the application deployed!

## Workshop Outline

This workshop follows a progressive approach. We first learn how to debug on the host, and then continue
to apply those skills to a container environment and then finally a remote environment within a
kubernetes cluster.

### Debugging on host

* Learn how to let Delve compile and run your program
* Learn how to compile your program to best run under Delve

### Debugging within container

* Learn how to setup your host system and container to debug properly
* Learn how to copy debugger into container and debug within that environment
* Learn how to remote debug in container environment

### Debugging within cluster

* Learn how setup pods to run a debugger
* Learn how to copy debugging tools into pod containers
* Learn how to remote debug into containers running on kubernetes cluster
* Learn how to setup a brand new cluster to enable enhanced debug support