SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent

include .env

.PHONY: help
help: ## show this help	
	@cat $(MAKEFILE_LIST) | 
	grep -oP '^[a-zA-Z_-]+:.*?## .*$$' |
	sort |
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

###########################################
## These images are built by github actions
##########################################

Build = $(patsubst build-%,podx-%,$1)
Origin = $(patsubst build-%,%,$1)

.PHONY: build-alpine
build-alpine: ## buildah build alpine with added directories and entrypoint
	@echo "build $(call Build,$@) FROM docker.io/$(call Origin,$@):latest"
	podman pull docker.io/alpine:latest
	VERSION=$$(podman run --rm docker.io/alpine:latest /bin/ash -c 'cat /etc/os-release' | grep -oP 'VERSION_ID=\K.+')
	sed -i "s/ALPINE_VER=.*/ALPINE_VER=v$${VERSION}/" .env
	@CONTAINER=$$(buildah from docker.io/$(call Origin,$@):$${VERSION})
	@buildah run $${CONTAINER} mkdir -p -v  \
		/opt/proxy/conf \
		/opt/proxy/html \
		/etc/letsencrypt \
		/usr/local/xqerl/code \
		/usr/local/xqerl/priv/static/assets # setting up directories
	@buildah config --workingdir /opt/proxy/html $${CONTAINER} # setting working dir where files is the static-assets volume can be found
	@buildah config --label org.opencontainers.image.base.name=$(call Origin,$@):$${VERSION} $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='base $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='A base alpine FROM container. Built in dirs for openresty and xqerl' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	@buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
	@#buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

.PHONY: build-w3m
build-w3m: ## buildah build $(call Origin,$@)
	echo 'from: ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER)'
	CONTAINER=$$(buildah from ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER))
	buildah run $${CONTAINER} apk add --no-cache w3m 
	VERSION=$$(buildah run $${CONTAINER}  sh -c 'w3m --version 2>&1 | tee' | grep -oP '(\d+\.){2}\d+')
	sed -i "s/W3M_VER=.*/W3M_VER=v$${VERSION}/" .env
	@buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@#default to dump
	@buildah config --entrypoint '["w3m"]' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

# https://pkgs.alpinelinux.org/packages?name=curl&branch=v3.14
.PHONY: build-curl
build-curl: ## buildah build $(call Origin,$@) 
	echo 'from: ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER)'
	CONTAINER=$$(buildah from ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER))
	buildah run $${CONTAINER} apk add --no-cache $(call Origin,$@)
	VERSION=$$(buildah run $${CONTAINER}  sh -c 'curl --version 2>&1 | tee' | grep -oP '^curl \K(\d+\.){2}\d+')
	sed -i "s/CURL_VER=.*/CURL_VER=v$${VERSION}/" .env
	buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(ALPINE_VER) $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url=https://github.com/$(REPO_OWNER)/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	buildah config --cmd '' $${CONTAINER}
	buildah config --entrypoint '["curl"]' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

.PHONY: build-cmark
build-cmark: ## buildah build $(call Origin,$@) 
	echo 'from: ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER)'
	CONTAINER=$$(buildah from ghcr.io/$(REPO_OWNER)/podx-alpine:$(ALPINE_VER))
	buildah run $${CONTAINER} apk add --no-cache cmark
	VERSION=$$(buildah run $${CONTAINER}  sh -c 'cmark --version 2>&1 | tee' | grep -oP '(\d+\.){2}\d+')
	sed -i "s/CMARK_VER=.*/CMARK_VER=v$${VERSION}/" .env
	buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(ALPINE_VER) $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	buildah config --cmd '' $${CONTAINER}
	#default to dump
	buildah config --entrypoint '["cmark", "--to", "xml"]' $${CONTAINER}
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif


# https://github.com/openresty/docker-openresty/blob/master/alpine-apk/Dockerfile
.PHONY: build-openresty
build-openresty: ## buildah build: openresty as base build for podx
	@podman pull docker.io/openresty/openresty:alpine-apk
	@VERSION="$$(podman run openresty/openresty:alpine-apk sh -c 'openresty -v' 2>&1 | tee | sed 's/.*openresty\///' )"
	sed -i "s/OPENRESTY_VER=.*/OPENRESTY_VER=v$${VERSION}/" .env
	@echo "openresty version: $${VERSION}"
	@CONTAINER=$$(buildah from docker.io/openresty/openresty:alpine-apk)
	@buildah run $${CONTAINER} mkdir -p \
		/opt/proxy/cache \
		/opt/proxy/html \
		/opt/proxy/logs \
		/opt/proxy/conf \
		/etc/letsencrypt
	@buildah copy $${CONTAINER} src/proxy/conf/. /opt/proxy/conf/
	@buildah run $${CONTAINER} sh -c 'rm /usr/local/openresty/nginx/conf/*  /usr/local/openresty/nginx/html/* /etc/init.d/* /etc/conf.d/*' 
	@buildah config --workingdir /opt/proxy/ $${CONTAINER} 
	@buildah config --label org.opencontainers.image.base.name=openresty/openresty:alpine-apk $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='nginx reverse-proxy and cache server' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@): image used as a running container in a podman pod' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/$(REPO_OWNER)/$(REPO)/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version="$${VERSION}" $${CONTAINER} # version
	@buildah config --env lang=C.UTF-8 $${CONTAINER}
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '[ "openresty", "-p", "/opt/proxy/", "-c", "/opt/proxy/conf/proxy.conf", "-g", "daemon off;"]' $${CONTAINER}
	@buildah run $${CONTAINER} sh -c 'openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -t'
	@buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
	@#buildah tag ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION} docker.io/$(REPO_OWNER)/$(call Build,$@):$${VERSION}
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

