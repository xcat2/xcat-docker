NAME=xcat2
REGISTRY=docker.io
USERNAME=$(USER)

IMAGE=$(REGISTRY)/$(USERNAME)/$(NAME)
VERSION=devel

SHELL=/bin/bash
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
		ubuntu manifest all

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
manifest:
	@echo "INFO: create manifest $(IMAGE):$(STABLE_VER) from $(DOCKER_BUILD_MANIFEST)..."
	docker run -v $(DOCKER_BUILD_MANIFEST):/xcat2.yml --rm mplatform/manifest-tool --debug --username=$(USER) push from-spec /xcat2.yml

help:
	@echo "make build"
	@echo "make build USER=xcat"
	@echo "make push USER=xcat VERSION=latest"
	@echo "make manifest USER=myname DOCKER_BUILD_MANIFEST=`pwd`/manifest.yml"
	@echo "make all"
	@echo "make all ubuntu=1"
