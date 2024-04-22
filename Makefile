SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
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

.PHONY: versions
versions:
	podman pull cgr.dev/chainguard/wolfi-base:latest
	VERSION=$$(podman run --rm cgr.dev/chainguard/wolfi-base /bin/ash -c 'cat /etc/os-release' | grep -oP 'VERSION_ID=\K.+')
	sed -i "s/WOLFI_VER=.*/WOLFI_VER=$${VERSION}/" .env
	echo " - wolfi version: $$VERSION"


xxxx:
	podman pull docker.io/openresty/openresty:alpine-apk
	VERSION="$$(podman run openresty/openresty:alpine-apk sh -c 'openresty -v' 2>&1 | tee | sed 's/.*openresty\///' )"
	sed -i "s/OPENRESTY_VER=.*/OPENRESTY_VER=v$${VERSION}/" .env
	echo "openresty version: $${VERSION}"


.PHONY: build
build: lua-language-server

# build-alpine build-w3m build-curl build-cmark certs build-openresty


clean:
	rm latest/lua_language_server.txt || true


shellcheck:
	CONTAINER=$$(buildah from cgr.dev/chainguard/wolfi-base)
	buildah run $${CONTAINER} sh -c 'apk add wget'
	buildah run $${CONTAINER} sh -c 'wget -q -O- https://github.com/koalaman/shellcheck/releases/download/stable/shellcheck-stable.linux.x86_64.tar.xz | \
	tar xJv'
	buildah run $${CONTAINER} sh -c 'ls -al /'
	buildah commit --rm $${CONTAINER} $@

bldr-bashls:
	CONTAINER=$$(buildah from cgr.dev/chainguard/node)
	buildah config --workingdir  '/app' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'npm i bash-language-server'
	buildah run $${CONTAINER} sh -c 'ls -al .'
	buildah commit --rm $${CONTAINER} $@


bash-language-server: shellcheck bldr-bashls
	CONTAINER=$$(buildah from cgr.dev/chainguard/wolfi-base)
	buildah config \
	--label summary='a Wolfi based bash-language-server' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'apk add nodejs-18 && mkdir -p /usr/local/bin'
	buildah run $${CONTAINER} sh -c 'whoami'
	buildah add --chmod 755 --from localhost/shellcheck $${CONTAINER} '/shellcheck-stable/shellcheck' '/usr/local/bin/shellcheck'
	buildah run $${CONTAINER} sh -c 'which shellcheck'
	buildah run $${CONTAINER} sh -c 'shellcheck --version'
	buildah add --chown root:root --from localhost/bldr-bashls $${CONTAINER} '/app' '/'
	buildah run $${CONTAINER} sh -c 'ln -s /node_modules/bash-language-server/out/cli.js /usr/local/bin/bash-language-server'
	buildah run $${CONTAINER} sh -c 'which bash-language-server'
	buildah config --entrypoint  '["bash-language-server", "start"]' $${CONTAINER}
	VERSION=$$(buildah run $${CONTAINER} sh -c 'bash-language-server --version' | grep -oP '(\d+\.){2}\d+' | head -1 )
	sed -i "s/BASH_LANGUAGE_SERVER=.*/BASH_LANGUAGE_SERVER=\"$${VERSION}\"/" .env
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$@
	podman images
	podman inspect ghcr.io/$(REPO_OWNER)/$@
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$@
endif

# vscode-css-language-server -> ../vscode-langservers-extracted/bin/vscode-css-language-server
# vscode-eslint-language-server -> ../vscode-langservers-extracted/bin/vscode-eslint-language-server
# vscode-html-language-server -> ../vscode-langservers-extracted/bin/vscode-html-language-server
# vscode-json-language-server -> ../vscode-langservers-extracted/bin/vscode-json-language-server
# vscode-markdown-language-server -> ../vscode-langservers-extracted/bin/vscode-markdown-language-server
# @NOTE: keep everything as is? leave npm intact?
vscode-langservers-extracted:
	CONTAINER=$$(buildah from cgr.dev/chainguard/node)
	buildah config --workingdir  '/app' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'npm install vscode-langservers-extracted'
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$@
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$@
endif

bldr-yamlls:
	CONTAINER=$$(buildah from cgr.dev/chainguard/node)
	buildah config --workingdir  '/app' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'npm i yaml-language-server'
	buildah run $${CONTAINER} sh -c 'ls -al node_modules/'
	buildah commit --rm $${CONTAINER} $@

yaml-language-server: bldr-yamlls
	CONTAINER=$$(buildah from cgr.dev/chainguard/wolfi-base)
	buildah config \
	--label summary='a Wolfi based yaml-language-server' \
	--label maintainer='Grant MacKenzie <grantmacken@gmail.com>' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'apk add nodejs-21'
	buildah add --chown root:root --from localhost/bldr-yamlls $${CONTAINER} '/app' '/'
	buildah config --workingdir  '/node_modules/yaml-language-server' $${CONTAINER}
	buildah config --entrypoint  '["./bin/yaml-language-server", "--stdio"]' $${CONTAINER}
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$@
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$@
endif
	podman images

xxx:
	buildah run $${CONTAINER} sh -c 'ln -s /node_modules/bash-language-server/out/cli.js /usr/local/bin/bash-language-server'
	buildah config --entrypoint  '["bash-language-server", "start"]' $${CONTAINER}
	VERSION=$$(buildah run $${CONTAINER} sh -c 'bash-language-server --version' | grep -oP '(\d+\.){2}\d+' | head -1 )
	sed -i "s/BASH_LANGUAGE_SERVER=.*/BASH_LANGUAGE_SERVER=\"$${VERSION}\"/" .env
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$@
	podman images
	podman inspect ghcr.io/$(REPO_OWNER)/$@
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$@
endif




check:
	# podman images
	# podman inspect localhost/bldr-node
	podman run --rm --entrypoint '["/bin/sh", "-c"] ' localhost/bldr-node 'ls -al node_modules/.bin'
	podman run --rm --entrypoint '["/bin/sh", "-c"] ' localhost/bldr-node 'printenv'
	podman run --rm --entrypoint '["/bin/sh", "-c"] ' localhost/shellcheck 'ls -al /usr/local/bin/shellcheck-stable'
	echo '-----------------'



latest/lua_language_server.txt:
	mkdir -p $(dir $@)
	wget -q -O - 'https://api.github.com/repos/LuaLS/lua-language-server/releases/latest' |
	jq -r '.assets[].browser_download_url' |
	grep linux-x64.tar.gz | tee $@

lua-language-server: latest/lua_language_server.txt
	echo '##[ $@ ]##'
	# 'objdump -p /app/bin/lua-language-server | grep NEEDED'
	# https://edu.chainguard.dev/chainguard/chainguard-images/reference/glibc-dynamic/image_specs/
	VERSION=$$(grep -oP '(\d+\.){2}\d+' $< | head -1 )
	sed -i "s/LUA_LANGUAGE_SERVER=.*/LUA_LANGUAGE_SERVER=\"$${VERSION}\"/" .env
	CONTAINER=$$(buildah from cgr.dev/chainguard/wolfi-base)
	buildah run $${CONTAINER} sh -c 'apk add wget libgcc' &>/dev/null
	# buildah run $${CONTAINER} sh -c 'apk add build-base glibc wget'
	buildah run $${CONTAINER} sh -c 'mkdir -p /app'
	cat $< | buildah run $${CONTAINER} sh -c 'cat - | wget -q -O- -i- | tar xvz -C /app' &>/dev/null
	# buildah run $${CONTAINER} sh -c '/app/bin/lua-language-server --version'
	# buildah run $${CONTAINER} sh -c 'objdump -p /app/bin/lua-language-server | grep NEEDED' || true
	# buildah run $${CONTAINER} sh -c 'ls -al /lib' || true
	buildah commit --rm $${CONTAINER} bldr
	CONTAINER=$$(buildah from cgr.dev/chainguard/glibc-dynamic:latest)
	buildah add --chmod 755 --chown nonroot:nonroot --from localhost/bldr $${CONTAINER} '/app' '/app'
	buildah config --entrypoint  '["/app/bin/lua-language-server"]' $${CONTAINER}
	buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$@
	podman images
	podman inspect ghcr.io/$(REPO_OWNER)/$@
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$@
endif





pull:
	podman pull ghcr.io/grantmacken/lua-language-server







.PHONY: build-alpine
build-alpine: ## buildah build alpine with added directories and entrypoint
	echo "build $(call Build,$@) FROM docker.io/$(call Origin,$@):latest"
	podman pull docker.io/alpine:latest
	VERSION=$$(podman run --rm docker.io/alpine:latest /bin/ash -c 'cat /etc/os-release' | grep -oP 'VERSION_ID=\K.+')
	sed -i "s/ALPINE_VER=.*/ALPINE_VER=v$${VERSION}/" .env
	echo " - alpine version: $$VERSION"
	CONTAINER=$$(buildah from docker.io/alpine:$${VERSION})
	buildah run $${CONTAINER} mkdir -p -v  \
		/opt/proxy/conf \
		/opt/proxy/html \
		/etc/letsencrypt \
		/usr/local/xqerl/code \
		/usr/local/xqerl/priv/static/assets # setting up directories
	buildah config --workingdir /opt/proxy/html $${CONTAINER} # setting working dir where files is the static-assets volume can be found
	buildah config --label org.opencontainers.image.base.name=$(call Origin,$@):$${VERSION} $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='base $(call Origin,$@) image' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='A base alpine FROM container. Built in dirs for openresty and xqerl' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
	#buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
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
build-cnurl: ## buildah build $(call Origin,$@) 
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
#
certs: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem src/proxy/conf/certs.conf
certs-pem: src/proxy/certs/example.com.pem # or must be running locally

certs-clean:
	echo '##[ $@ ]##'
	rm -fv src/proxy/certs/*


src/proxy/certs/example.com.key:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	 openssl genrsa -out $@ 2048

src/proxy/certs/example.com.csr: src/proxy/certs/example.com.key
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	openssl req -new -key $<  \
		-nodes \
		-subj '/C=NZ/CN=example.com' \
		-out $@ -sha512

src/proxy/certs/example.com.crt: src/proxy/certs/example.com.csr
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	openssl x509 -req -days 365 -in $< -signkey src/proxy/certs/example.com.key -out $@ -sha512

src/proxy/certs/dhparam.pem:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '##[ $(notdir $@) ]##'
	openssl dhparam -out $@ 2048

src/proxy/conf/certs.conf:
	[ -d $(dir $@) ] || mkdir -p $(dir $@)
	echo '## $(notdir $@) ##'
	echo "ssl_certificate /opt/proxy/certs/example.com.crt;" > $@
	echo "ssl_certificate_key /opt/proxy/certs/example.com.key;" >> $@
	echo "ssl_dhparam /opt/proxy/certs/dhparam.pem;" >> $@


.PHONY: build-openresty
build-openresty: ## buildah build: openresty as base build for podx
	podman pull docker.io/openresty/openresty:alpine-apk
	VERSION="$$(podman run openresty/openresty:alpine-apk sh -c 'openresty -v' 2>&1 | tee | sed 's/.*openresty\///' )"
	sed -i "s/OPENRESTY_VER=.*/OPENRESTY_VER=v$${VERSION}/" .env
	echo "openresty version: $${VERSION}"
	CONTAINER=$$(buildah from docker.io/openresty/openresty:alpine-apk)
	buildah run $${CONTAINER} mkdir -p \
		/opt/proxy/cache \
		/opt/proxy/certs \
		/opt/proxy/html \
		/opt/proxy/logs \
		/opt/proxy/conf \
		/etc/letsencrypt \
		/usr/local/xqerl/priv/static/assets # setting up directories
	buildah copy $${CONTAINER} src/proxy/conf/. /opt/proxy/conf/
	buildah copy $${CONTAINER} src/proxy/certs/. /opt/proxy/certs/
	buildah run $${CONTAINER} sh -c 'rm /usr/local/openresty/nginx/conf/*  /usr/local/openresty/nginx/html/* /etc/init.d/* /etc/conf.d/*' 
	buildah config --workingdir /opt/proxy/ $${CONTAINER} 
	buildah config --label org.opencontainers.image.base.name=openresty/openresty:alpine-apk $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='nginx reverse-proxy and cache server' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@): image used as a running container in a podman pod' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url=https://github.com/$(REPO_OWNER)/$(REPO)/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version="$${VERSION}" $${CONTAINER} # version
	buildah config --env lang=C.UTF-8 $${CONTAINER}
	buildah config --cmd '' $${CONTAINER}
	buildah config --entrypoint '[ "openresty", "-p", "/opt/proxy/", "-c", "/opt/proxy/conf/proxy.conf", "-g", "daemon off;"]' $${CONTAINER}
	buildah run $${CONTAINER} sh -c 'openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -t' || true
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
	#buildah tag ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION} docker.io/$(REPO_OWNER)/$(call Build,$@):$${VERSION}
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

# .PHONY: build-tinylr
# build-tinylr: ## buildah build cssnano
# 	CONTAINER=$$(buildah from docker.io/node:alpine$(ALPINE_VER))
# 	buildah run $${CONTAINER} npm install -g make-livereload
	#buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}

.PHONY: build-node
build-node: ## buildah build node
	echo "build base $(call Origin,$@) image"
	podman pull docker.io/node:current-alpine
	VERSION=$$(podman run --rm docker.io/node:current-alpine /bin/ash -c 'cat /etc/os-release' | grep -oP 'VERSION_ID=\K.+')
	sed -i "s/NODE_VER=.*/NODE_VER=v$${VERSION}/" .env
	CONTAINER=$$(buildah from docker.io/node:current-alpine)
	buildah run $${CONTAINER} mkdir -p -v  \
		/opt/proxy/conf \
		/opt/proxy/html \
		/etc/letsencrypt \
		/usr/local/xqerl/code \
		/usr/local/xqerl/priv/static/assets # setting up directories
	buildah config --workingdir /usr/local/xqerl/priv/static/assets $${CONTAINER} # setting working dir where files is the static-assets volume can be found
	buildah config --label org.opencontainers.image.base.name=node:current-alpine $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='base $(call Origin,$@) image' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='A base alpine FROM container. Built in dirs for static assets' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
endif

.PHONY: build-browsersync
build-browsersync: ## buildah build node
	echo "build  podx-$(call Origin,$@) image"
	echo 'from: ghcr.io/$(REPO_OWNER)/podx-node:$(NODE_VER)'
	CONTAINER=$$(buildah from ghcr.io/$(REPO_OWNER)/podx-node:$(NODE_VER))
	buildah run $${CONTAINER} npm install -g browser-sync
	buildah config --cmd '' $${CONTAINER}
	buildah config --entrypoint '["browser-sync"]' $${CONTAINER}
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(NODE_VER)

# .PHONY: bs
# bs:
# 	podman run --rm -it --name bs \
# 		-p 3000:3000 \
#     -p 3001:3001 \
# 		--mount  type=volume,target=/usr/local/xqerl/priv/static/assets,source=static-assets \
# 		ghcr.io/grantmacken/podx-browsersync:$(NODE_VER) https://gmack.nz --no-open --files './**/*.css' 

# xxxxxxx:
#         @CONTAINER=$$(buildah from docker.io/node:alpine$(FROM_ALPINE_VER))
#         @buildah run $${CONTAINER} npm install -g cssnano postcss postcss-cli
#         @buildah run $${CONTAINER} mkdir -p -v /opt/proxy/html
#         @buildah config --workingdir /opt/proxy/html $${CONTAINER}
#         @buildah config --cmd '' $${CONTAINER}
#         @buildah config --entrypoint '["/usr/local/bin/postcss"]' $${CONTAINER}
#         @buildah commit $${CONTAINER} cssnano
#         @buildah config --label org.opencontainers.image.base.name=node:alpine$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
#         @buildah config --label org.opencontainers.image.title='node-alpine based image$(call Origin,$@) image' $${CONTAINER} # title
#         @buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
#         @buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
#         @buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
#         @buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
#         @buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
#         @buildah config --label org.opencontainers.image.version='$(GHPKG_CSSNANO_VER)' $${CONTAINER} # version
#         @buildah config --cmd '' $${CONTAINER}
#         @buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
#         @buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CSSNANO_VER)
# ifdef GITHUB_ACTIONS
#         @buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CSSNANO_VER)
# endif

.PHONY: lsp-lua
lsp-lua:
	podman pull docker.io/alpine:latest
	VERSION=$$(podman run --rm docker.io/alpine:latest /bin/ash -c 'cat /etc/os-release' | grep -oP 'VERSION_ID=\K.+')
	echo "Alpine Version: $${VERSION}"
	CONTAINER=$$(buildah from docker.io/alpine:latest)
	buildah run $${CONTAINER} apk add --no-cache build-base git ninja
	buildah config --workingdir /home $${CONTAINER} 
	buildah run $${CONTAINER} /bin/sh \
	-c 'git clone --depth 1 --branch "2.6.0" https://github.com/sumneko/lua-language-server \
  && cd lua-language-server \
  && git submodule update --init --recursive \
  && ninja -C 3rd/luamake -f compile/ninja/linux.ninja \
  && ./3rd/luamake/luamake rebuild \
	&& ls -alR ./build'
	buildah commit --rm $${CONTAINER} localhost/lsp-buildr
	CONTAINER=$$(buildah from docker.io/alpine:latest)
	buildah config --workingdir /home $${CONTAINER} 
	buildah  copy --from 'localhost/lsp-buildr'  $${CONTAINER}  '/home' '/home'
	buildah config --cmd '' $${CONTAINER}
	VERSION=$$(buildah run $${CONTAINER}  sh -c '/home/lua-language-server/bin/lua-language-server --version')
	buildah config --label org.opencontainers.image.base.name=alpine $${CONTAINER} # image is built FROM
	buildah config --label org.opencontainers.image.title='lua-language-server image' $${CONTAINER} # title
	buildah config --label org.opencontainers.image.descriptiion='sumneko lua language server  ' $${CONTAINER} # description
	buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	buildah config --label org.opencontainers.image.source'=https://github.com/$(REPO_OWNER)/$(REPO)' $${CONTAINER} # where the image is built
	buildah config --label org.opencontainers.image.documentation='https://github.com/$(REPO_OWNER)/$(REPO)' $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.url='https://github.com/grantmacken/podx/pkgs/container/lua-language-server' $${CONTAINER} # url
	buildah config --label org.opencontainers.image.version='v$${VERSION}' $${CONTAINER} # version
	buildah config --workingdir /home/lua-language-server $${CONTAINER}
	buildah config --entrypoint '[ "./bin/lua-language-server", "-E", "./bin/main.lua" ]' $${CONTAINER}
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/lua-language-server:v$${VERSION}
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/lua-language-server:v$${VERSION}
endif
	buildah rmi localhost/lsp-buildr


.PHONY: lsp-erlang
lsp-erlang:
	podman pull docker.io/erlang:alpine
	OTP_VERSION=$$(podman run --rm docker.io/erlang:alpine sh -c 'cat /usr/local/lib/erlang/releases/*/OTP_VERSION')
	echo " - uses erlang OTP version: $${OTP_VERSION}"
	CONTAINER=$$(buildah from docker.io/erlang:alpine)
	buildah run $${CONTAINER} apk add --no-cache build-base openssl ncurses-libs tzdata libstdc++ git tar
	buildah run $${CONTAINER} /bin/sh \
	-c 'git clone --depth 1 https://github.com/erlang-ls/erlang_ls \
  && cd erlang_ls && make && make install'
	# VERSION=$$(buildah run $${CONTAINER}  sh -c '/usr/local/bin/erlang_ls --version')
	buildah config --label org.opencontainers.image.base.name=erlang_ls $${CONTAINER}
	buildah config --label org.opencontainers.image.title='lsp erlang server' $${CONTAINER}
	buildah config --label org.opencontainers.image.description='An Erlang server implementing Language Server Protocol' $${CONTAINER}
	buildah config --label org.opencontainers.image.source=https://github.com/${GITHUB_REPOSITORY} $${CONTAINER} # where the image is built
	#buildah config --label org.opencontainers.image.documentation=https://github.com//${GITHUB_REPOSITORY} $${CONTAINER} # image documentation
	buildah config --label org.opencontainers.image.version=:v$${OTP_VERSION} $${CONTAINER} # version
	buildah config --workingdir /home $${CONTAINER}
	buildah config --entrypoint '[ "erlang_ls", "--transport", "stdio"]' $${CONTAINER}
	buildah commit --rm --squash $${CONTAINER} ghcr.io/$(REPO_OWNER)/erlang_ls:v$${OTP_VERSION}
	podman images
ifdef GITHUB_ACTIONS
	buildah push ghcr.io/$(REPO_OWNER)/erlang_ls:v$${OTP_VERSION}
endif

.PHONY: t
t:
	podman run --rm  -i localhost/erlang_ls:v25.0.1 
