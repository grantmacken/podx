###########################################
## These images are built by github actions
##########################################

Build = $(patsubst build-%,podx-%,$1)
Origin = $(patsubst build-%,%,$1)

.PHONY: build-images
build-images: alpine-base-images node-alpine-images build-openresty build-or build-xq ## buildah build all images

.PHONY: alpine-base-images
alpine-base-images: build-alpine build-curl build-w3m build-cmark build-zopfli build-magick 

.PHONY: node-alpine-images
node-alpine-images: build-cssnano build-webpack
#  - build-w3m
#  - build-cmark
#  - build-zopfli
#  - build-magick

########################
# from base alpine:
#  - podx-alpine
#  - podx-w3m
#  - podx-cmark
#  - podx-zopfli
#  - podx-magick
#  - podx-openresty
# from base node:alpine:
#  - podx-cssnano
#  - podx-webpack
#######################

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
	@buildah config --entrypoint '["w3m" "-dump" ]' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} ghcr.io/$(REPO_OWNER)/$(call Build,$@):v$${VERSION}
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_W3M_VER)
endif


# https://pkgs.alpinelinux.org/packages?name=curl&branch=v3.14
.PHONY: build-curl
build-curl: ## buildah build $(call Origin,$@) 
	@CONTAINER=$$(buildah from localhost/alpine)
	@buildah run $${CONTAINER} apk add --no-cache $(call Origin,$@)
	@buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_CURL_VER)' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["curl"]' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CURL_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CURL_VER)
endif


# https://github.com/commonmark/cmark/releases
.PHONY: build-cmark
build-cmark: ## buildah build cmark - built with cmark release tar
	@CONTAINER=$$(buildah from localhost/alpine)
	@buildah run $${CONTAINER} /bin/sh -c \
		'apk add --virtual .build-deps build-base cmake \
		&& cd /home \
		&& wget -O cmark.tar.gz https://github.com/commonmark/cmark/archive/$(GHPKG_CMARK_VER).tar.gz \
		&& tar -C /tmp -xf ./cmark.tar.gz \
    && cd /tmp/cmark-$(GHPKG_CMARK_VER) \
    && cmake \
    && make install \
    && cd /home \
    && rm -f ./cmark.tar.gz \
    && rm -r /tmp/cmark-$(GHPKG_CMARK_VER) \
    && apk del .build-deps \
		'
	@buildah run $${CONTAINER} ls -alR /home
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/local/bin/cmark"]' $${CONTAINER}
	@buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_CMARK_VER)' $${CONTAINER} # version
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CMARK_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CMARK_VER)
endif

.PHONY: build-zopfli
build-zopfli: ## buildah build zopfli
	@CONTAINER=$$(buildah from localhost/alpine)
	@buildah run $${CONTAINER} apk add --no-cache zopfli
	@buildah run $${CONTAINER} sh -c 'echo "#!/bin/sh -l" > /home/stdin-zopfli' 
	@buildah run $${CONTAINER} sh -c 'echo "cat - > /tmp/tmpfile" >> /home/stdin-zopfli' 
	@buildah run $${CONTAINER} sh -c 'echo "zopfli -c /tmp/tmpfile" >> /home/stdin-zopfli' 
	@buildah run $${CONTAINER} sh -c 'chmod +x /home/stdin-zopfli' 
	@buildah run $${CONTAINER} sh -c 'ls -al /home/stdin-zopfli' 
	@buildah run $${CONTAINER} sh -c 'cat /home/stdin-zopfli' 
	@buildah run $${CONTAINER} mkdir -p /opt/proxy/html/images /opt/proxy/html/icons /opt/proxy/html/styles
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/home/stdin-zopfli"]' $${CONTAINER}
	@buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='alpine based $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_ZOPFLI_VER)' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_ZOPFLI_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_ZOPFLI_VER)
endif

.PHONY: build-magick
build-magick: ## buildah build imagemagick
	@CONTAINER=$$(buildah from localhost/alpine )
	@buildah run $${CONTAINER} apk add --no-cache imagemagick
	@buildah run $${CONTAINER} mkdir -p /opt/proxy/html/images
	@buildah config --workingdir /opt/proxy/html/images $${CONTAINER}
	@buildah config --label org.opencontainers.image.base.name=$(REPO_OWNER)/podx-alpine:$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='alpine based image$(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_MAGICK_VER)' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_MAGICK_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_MAGICK_VER)
endif

###########
# webpack and cssnano based on node:apline
# #########

.PHONY: build-cssnano
build-cssnano: ## buildah build cssnano
	@CONTAINER=$$(buildah from docker.io/node:alpine$(FROM_ALPINE_VER))
	@buildah run $${CONTAINER} npm install -g cssnano postcss postcss-cli
	@buildah run $${CONTAINER} mkdir -p -v /opt/proxy/html
	@buildah config --workingdir /opt/proxy/html $${CONTAINER}
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/local/bin/postcss"]' $${CONTAINER}
	@buildah commit $${CONTAINER} cssnano
	@buildah config --label org.opencontainers.image.base.name=node:alpine$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='node-alpine based image$(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used to in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_CSSNANO_VER)' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CSSNANO_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_CSSNANO_VER)
endif

.PHONY: build-webpack
build-webpack: ## buildah build webpack
	@CONTAINER=$$(buildah from docker.io/node:alpine$(FROM_ALPINE_VER))
	@buildah run $${CONTAINER} npm install -g webpack webpack-cli
	@buildah run $${CONTAINER} mkdir -p -v /opt/proxy/html
	@buildah config --workingdir /opt/proxy/html $${CONTAINER}
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/local/bin/webpack"]' $${CONTAINER}
	@buildah config --label org.opencontainers.image.base.name=node:alpine$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='node-alpine based $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='$(call Build,$@) to be used in stdin-stdout podx workflow' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(GHPKG_WEBPACK_VER)' $${CONTAINER} # version
	@buildah config --cmd '' $${CONTAINER}
	@buildah commit --rm $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_WEBPACK_VER)
ifdef GITHUB_ACTIONS
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(GHPKG_WEBPACK_VER)
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

# https://github.com/postcss/postcss-cli
##################
## checks: xqerl
##################

.PHONY: run-xqerl-ash
run-xqerl-ash: podx
	@podman run --pod $(POD) -it --rm --entrypoint "/bin/ash" $(XQ)
	@podman ps --pod

.PHONY: xqerl-run
xqerl-run: podx
	@podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name xq --rm \
		 --detach $(XQ)
	@podman ps -a --pod

.PHONY: xqerl-check
xqerl-check: xqerl-run
	@sleep 3 && echo 'check: we can compile library module'
	@bin/xq compile src/library_modules/view.xqm || true
	@echo && echo 'check: reachable on port 8081' && sleep 2
	@#$(call DASH) && echo
	@curl -v http://localhost:8081/example.com/home/index || true
	@#$(call DASH) && echo
	@echo && echo 'check: is rachable the pods internal localhost network'
	@$(call DASH) && echo
	@$(W3M) -dump http://localhost:8081/example.com/home/index || true
	@$(call DASH) && echo

##################
## checks: proxy
##################

.PHONY: run-ash
run-ash: podx
	@podman run --pod $(POD) -it --rm --entrypoint "/bin/ash" $(OR)
	@podman ps -a --pod

.PHONY: proxy-run
proxy-run: xqerl-check
	@podman run --pod $(POD) \
		--rm --name or \
		--detach $(OR)

.PHONY: proxy-check
proxy-check: proxy-run
	@podman ps --pod
	@echo && echo 'check: example.com reachable on localhost'
	@curl -v http://example.com:8080 || true
	@echo && $(call DASH) && echo
	@podman pod stop -a || true
	@podman pod rm $(POD) || true

.PHONY: build-opm
build-opm:
	@#
	@IMG=$$(buildah from $(BUILD_FROM))
	@buildah config --label maintainer="Grant Mackenzie <grantmacken@gmail.com>" $${IMG}
	@buildah run $${IMG} apk del openresty
	@buildah run $${IMG} apk add openresty-opm
	@buildah config --workingdir /usr/local/openresty $${IMG}

