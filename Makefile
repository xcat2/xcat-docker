NAME=xcat2
REGISTRY=docker.io
ORGNAME=$(USER)

IMAGE=$(REGISTRY)/$(ORGNAME)/$(NAME)

SHELL=/bin/bash
VERSION=devel
ifeq ($(VERSION), latest)
	STABLE_VER:=$(shell curl -s http://xcat.org/files/xcat/repos/yum/$(VERSION)/xcat-core/buildinfo|grep VERSION=|cut -d '=' -f 2)
endif
STABLE_VER?=$(VERSION)
ARCH?=$(shell arch)
ifeq ($(ARCH),i386)
	ARCH:=x86_64
endif
TAG:=$(STABLE_VER)-$(ARCH)

DOCKER_BUILD_CONTEXT=.
# To build container with ubuntu, using different name and docker file
ifdef ubuntu
	DOCKER_FILE_PATH=ubuntu/Dockerfile
	NAME:=$(NAME)-ubuntu
endif
DOCKER_FILE_PATH?=Dockerfile

$(warning IMAGE=$(IMAGE) VERSION=$(VERSION) TAG=$(TAG))

.PHONY: pre-build docker-build post-build build \
		push pre-push do-push post-push \
		manifest all

all: build push manifest

build: pre-build docker-build post-build


pre-build:


post-build:


docker-build:
	@echo "INFO: building $(NAME) container (Tag=$(TAG)) ..."
	docker build $(DOCKER_BUILD_ARGS) -t $(NAME):$(TAG) $(DOCKER_BUILD_CONTEXT) -f $(DOCKER_FILE_PATH)
	#docker tag $(NAME):$(TAG) $(NAME):latest


push: pre-push do-push post-push

pre-push:


do-push:
	@echo "INFO: pushing $(IMAGE):$(TAG) ..."
	docker tag $(NAME):$(TAG) $(IMAGE):$(TAG)
	docker push $(IMAGE):$(TAG)
	docker rmi $(IMAGE):$(TAG)

post-push:


DOCKER_BUILD_MANIFEST:=$(shell pwd)/manifest/xcat-$(STABLE_VER).yml
ifdef DOCKER_PW
	DOCKER_AUTH_STRING=--username $(USER) --password $(DOCKER_PW)
endif
manifest:
	@echo "INFO: create manifest $(IMAGE):$(STABLE_VER) from $(DOCKER_BUILD_MANIFEST)..."
	docker run --rm \
		-v $(DOCKER_BUILD_MANIFEST):/xcat2.yml \
		-v $(HOME)/.docker:/tmp/docker-cfg \
		mplatform/manifest-tool --debug  --docker-cfg '/tmp/docker-cfg' $(DOCKER_AUTH_STRING) \
		push from-spec /xcat2.yml

help:
	@echo "make <target> [VERSION=latest REGISTRY=myregistry.org ORGNAME=xyz USER=myname ubuntu=1 ...]"
	@echo ""
	@echo "make build - build docker image"
	@echo "make push  - push docker image to docker registry"
	@echo "make manifest [ USER=myname DOCKER_BUILD_MANIFEST=`pwd`/manifest.yml ]" - create and push manifest
	@echo "make all  - build, push and create manifest"
	@echo "make all ubuntu=1 - ubuntu based container"
