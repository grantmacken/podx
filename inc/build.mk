###########################################
## These images are built by github actions
##########################################




Build = $(patsubst build-%,podx-%,$1)
Origin = $(patsubst build-%,%,$1)

.PHONY: build-images
build-images: build-alpine ## buildah build all images

.PHONY: build-alpine
build-alpine: ## buildah build alpine with added directories and entrypoint
	@echo "build $(call Build,$@) FROM docker.io/$(call Origin,$@):$(FROM_ALPINE_VER)"
	@CONTAINER=$$(buildah from docker.io/$(call Origin,$@):$(FROM_ALPINE_VER))
	@buildah run $${CONTAINER} mkdir -p -v  \
		/opt/proxy/certs \
		/opt/proxy/conf \
		/opt/proxy/html/fonts \
		/opt/proxy/html/images  \
		/opt/proxy/html/icons \
		/etc/letsencrypt \
		/usr/local/xqerl/code/src \
		/usr/local/xqerl/priv/static/assets # setting up directories
	@buildah config --workingdir /opt/proxy/html $${CONTAINER} # setting working dir where files is the static-assets volume can be found
	@buildah config --label org.opencontainers.image.base.name=$(call Origin,$@):$(FROM_ALPINE_VER) $${CONTAINER} # image is built FROM
	@buildah config --label org.opencontainers.image.title='base $(call Origin,$@) image' $${CONTAINER} # title
	@buildah config --label org.opencontainers.image.descriptiion='A base alpine FROM container. Built in dirs for openresty and xqerl' $${CONTAINER} # description
	@buildah config --label org.opencontainers.image.authors='Grant Mackenzie <$(REPO_OWNER)@gmail.com>' $${CONTAINER} # author
	@buildah config --label org.opencontainers.image.source=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # where the image is built
	@buildah config --label org.opencontainers.image.documentation=https://github.com/$(REPO_OWNER)/$(REPO) $${CONTAINER} # image documentation
	@buildah config --label org.opencontainers.image.url=https://github.com/grantmacken/podx/pkgs/container/$(call Build,$@) $${CONTAINER} # url
	@buildah config --label org.opencontainers.image.version='$(FROM_ALPINE_VER)' $${CONTAINER} # version
	@buildah commit $${CONTAINER} localhost/$(call Origin,$@)
	@buildah tag localhost/$(call Origin,$@) ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(FROM_ALPINE_VER)
	@buildah rm $${CONTAINER}
	@buildah push ghcr.io/$(REPO_OWNER)/$(call Build,$@):$(FROM_ALPINE_VER)


.PHONY: xqerl-build
xqerl-build: ## buildah build xqerl database and xQuery 3.1 engine
	@CONTAINER=$$(buildah from $(GHPKG_REGISTRY)/grantmacken/alpine-xqerl:$(FROM_XQERL_VER))
	@echo ' - make directories'
	@buildah run $${CONTAINER} mkdir -p \
		$(XQERL_HOME)/bin/scripts $(XQERL_HOME)/code/src $(XQERL_HOME)/priv/static/assets
	@buildah copy $${CONTAINER} src/escripts $(XQERL_HOME)/bin/scripts
	@buildah copy $${CONTAINER} src/library_modules $(XQERL_HOME)/code/src
	@buildah commit $${CONTAINER} xqerl
	@buildah tag localhost/xqerl $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-xq:$(GHPKG_XQ_VER))
	@buildah rm $${CONTAINER} 

# https://github.com/openresty/docker-openresty/blob/master/alpine-apk/Dockerfile
# TODO basic build then add certs
.PHONY: proxy-build
proxy-build: certs-create-self-signed ## buildah build: openresty as a reverse proxy container
	@CONTAINER=$$(buildah from docker.io/openresty/openresty:alpine-apk )
	@buildah run $${CONTAINER} sh -c 'openresty -v' || true
	@echo ' - make directories'
	@buildah run $${CONTAINER} mkdir -p \
		/opt/proxy/cache \
	  /opt/proxy/html \
		/opt/proxy/logs \
		/opt/proxy/conf \
		/opt/proxy/certs \
		/usr/local/openresty/site/lualib
	@buildah run $${CONTAINER} sh -c \
	'rm /usr/local/openresty/nginx/conf/*  /usr/local/openresty//nginx/html/* /etc/init.d/* /etc/conf.d/*' 
	@echo ' - copy nginx src files into /opt/proxy/conf'
	@buildah copy $${CONTAINER} src/proxy/conf /opt/proxy/conf
	@buildah copy $${CONTAINER} src/proxy/certs /opt/proxy/certs
	@echo ' - check new conf file ... /opt/proxy/conf/proxy.conf'
	@buildah run $${CONTAINER} sh -c 'openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -t' || true
	@#buildah config --created-by "$(REPO_OWNER)" $${CONTAINER}
	@echo ' - set working dir ...'
	@buildah config --workingdir $(PROXY_PREFIX) $${CONTAINER} 
	@echo ' - set entry point: with new prefix and alt config file'
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '[ "openresty", "-p", "$(PROXY_PREFIX)/", "-c", "$(PROXY_PREFIX)/conf/proxy.conf", "-g", "daemon off;"]' $${CONTAINER}
	@buildah config --env LANG=C.UTF-8 $${CONTAINER}
	@echo ' - commit ...'
	@buildah commit $${CONTAINER} proxy
	@buildah tag localhost/proxy $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-or:$(GHPKG_XQ_VER)
	@#buildah inspect --type=image proxy | jq '.'
	@buildah rm $${CONTAINER} 

.PHONY: w3m-build
w3m-build: ## buildah build w3m
	@CONTAINER=$$(buildah from localhost/alpine)
	@buildah run $${CONTAINER} apk add --no-cache w3m
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/bin/w3m"]' $${CONTAINER}
	@buildah commit $${CONTAINER} w3m
	@buildah tag localhost/w3m $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-w3m:$(GHPKG_W3M_VER)
	@buildah rm $${CONTAINER} 

.PHONY: cmark-build
cmark-build: ## buildah build w3m
	@CONTAINER=$$(buildah from localhost/alpine)
	@buildah run $${CONTAINER} apk add --no-cache cmark
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/bin/cmark"]' $${CONTAINER}
	@buildah run $${CONTAINER} which cmark
	@buildah commit $${CONTAINER} cmark
	@buildah tag localhost/cmark $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-cmark:$(GHPKG_CMARK_VER)
	@buildah rm $${CONTAINER} 

# && echo "cat - > /tmp/tmpfile" >> stdin-zopfli  
# && echo "zopfli -c /tmp/tmpfile" >> stdin-zopfli 

.PHONY: zopfli-build
zopfli-build: ## buildah build zopfli
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
	@buildah commit $${CONTAINER} zopfli
	@buildah tag localhost/zopfli $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-zopfli:$(GHPKG_ZOPFLI_VER)
	@buildah rm $${CONTAINER}

.PHONY: magick-build
magick-build: ## buildah build imagemagick
	@CONTAINER=$$(buildah from localhost/alpine )
	@buildah run $${CONTAINER} apk add --no-cache imagemagick
	@buildah run $${CONTAINER} mkdir -p /opt/proxy/html/images
	@#buildah config --cmd '' $${CONTAINER}
	@#buildah config --entrypoint '["/bin/ash", "-c" ]' $${CONTAINER}
	@buildah config --workingdir /opt/proxy/html/images $${CONTAINER}
	@buildah commit $${CONTAINER} magick
	@buildah tag localhost/magick $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-magick:$(GHPKG_MAGICK_VER)
	@buildah rm $${CONTAINER} 


.PHONY: webpack-build
webpack-build: ## buildah build webpack
	@CONTAINER=$$(buildah from docker.io/node:alpine$(FROM_ALPINE_VER))
	@buildah run $${CONTAINER} npm install -g webpack webpack-cli
	@buildah run $${CONTAINER} webpack -v
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/local/bin/webpack"]' $${CONTAINER}
	@buildah commit $${CONTAINER} webpack
	@#buildah tag localhost/webpack $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-webpack:$(GHPKG_ZOPFLI_VER))
	@buildah rm $${CONTAINER}

# https://github.com/postcss/postcss-cli
#
.PHONY: cssnano-build
cssnano-build: ## buildah build webpack
	@CONTAINER=$$(buildah from docker.io/node:alpine$(FROM_ALPINE_VER))
	@buildah run $${CONTAINER} npm install -g cssnano postcss postcss-cli
	@buildah run $${CONTAINER} which npx
	@buildah run $${CONTAINER} ls -alR /usr/local/bin
	@buildah config --cmd '' $${CONTAINER}
	@buildah config --entrypoint '["/usr/local/bin/postcss"]' $${CONTAINER}
	@buildah commit $${CONTAINER} cssnano
	@#buildah tag localhost/webpack $(GHPKG_REGISTRY)/$(REPO_OWNER)/podx-cssnano:$(GHPKG_ZOPFLI_VER))
	@buildah rm $${CONTAINER}

##################
## checks: xqerl
##################

.PHONY: run-xqerl-ash
run-xqerl-ash: podx
	@podman run --pod $(POD) -it --rm --entrypoint "/bin/ash" $(XQERL_IMAGE)
	@podman ps --pod

.PHONY: xqerl-run
xqerl-run: podx
	@podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name xq --rm \
		 --detach $(XQERL_IMAGE)
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
	@podman run --pod $(POD) -it --rm --entrypoint "/bin/ash" $(PROXY_IMAGE)
	@podman ps -a --pod

.PHONY: proxy-run
proxy-run: xqerl-check
	@podman run --pod $(POD) \
		--rm --name or \
		--detach $(PROXY_IMAGE)

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

