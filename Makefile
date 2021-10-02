SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
# invoke with alias mk 
include .env
# images
#ALPINE    := ghcr.io/grantmacken/podx-alpine:$(GHPKG_ALPINE_VER)
CMARK     := ghcr.io/grantmacken/podx-cmark:$(GHPKG_CMARK_VER)
MAGICK    := ghcr.io/grantmacken/podx-magick:$(GHPKG_MAGICK_VER)
W3M       := ghcr.io/grantmacken/podx-w3m:$(GHPKG_W3M_VER)
ZOPFLI    := ghcr.io/grantmacken/podx-zopfli:$(GHPKG_ZOPFLI_VER)
CSSNANO   := ghcr.io/grantmacken/podx-cssnano:$(GHPKG_CSSNANO_VER)
WEBPACK   := ghcr.io/grantmacken/podx-webpack:$(GHPKG_WEBPACK_VER)
OPENRESTY := ghcr.io/grantmacken/podx-openresty:$(FROM_OPENRESTY_VER)
ALPINE    := ghcr.io/grantmacken/podx-alpine:$(FROM_ALPINE_VER)

CURL := docker.io/curlimages/curl:latest

XQ        := ghcr.io/grantmacken/podx-xq:$(GHPKG_XQ_VER)
OR        := ghcr.io/grantmacken/podx-or:$(GHPKG_OR_VER)

PROXY_IMAGE=proxy
# OPM_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(PROXY_NAME):opm-$(PROXY_VER)
#RESTY_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(PROXY_NAME):resty-$(PROXY_VER)
XQERL_IMAGE=xqerl
# proxy mounts
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
MountCerts       := type=volume,target=/opt/proxy/certs,source=certs
MountProxyConf   := type=volume,target=/opt/proxy/conf,source=proxy-conf
MountAssets      := type=volume,target=/opt/proxy/html,source=static-assets
MountLualib      := type=volume,target=/usr/local/openresty/site/lualib,source=lualib
# xqerl mounts
MountCode        := type=volume,target=/usr/local/xqerl/code,source=xqerl-compiled-code
MountData        := type=volume,target=/usr/local/xqerl/data,source=xqerl-database
#MountEscripts   := type=volume,target=$(XQERL_HOME)/bin/scripts,source=xqerl-escripts
DASH = printf %60s | tr ' ' '-' && echo

.PHONY: help
help: ## show this help	
	@cat $(MAKEFILE_LIST) | 
	grep -oP '^[a-zA-Z_-]+:.*?## .*$$' |
	sort |
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

include inc/*.mk

#CONNECT_TO := --connect-to $(XQ):80:xq.$(NETWORK):$(XQERL_PORT) 
#RESOLVE := --resolve $(XQ):$(XQERL_PORT):$(ipAddress)
#CURL := docker run --pod $(POD) --rm --interactive  $(CURL_IMAGE) $(CONNECT_TO)

.PHONY: crl
crl:
	@$(DASH)
	@curl -vkL http://example.com:8080 || true
	@$(DASH)
	@curl -vk https://example.com:8443 || true
	@$(DASH)
	@#openssl s_client -showcerts -connect example.com:8443 </dev/null | sed -n -e '/-.BEGIN/,/-.END/ p'
	@#podman run --pod $(POD) --rm --interactive  $(CURL) -v http://localhost:8081/example.co
	#podman run --pod $(POD) --rm -it  localhost/w3m -dump_extra http://localhost:8081/example.com/home/index
	#podman run --pod $(POD) --rm -it  localhost/w3m -dump http://localhost:8081/example.com/home/index

.PHONY: check
check: 
	@#podman ps --pod
	@#echo && echo 'check: example.com reachable on localhost'
	@#echo && $(DASH) && echo
	@#w3m -dump_head http://example.com:8080
	@#$(DASH) && echo
	@#w3m -dump https://example.com:8443
	@#$(DASH) && echo
	@#$(DASH) && echo
	@curl -v http://example.com:8080 || true
	@#$(DASH) && echo
	@#openssl s_client -showcerts -connect example.com:8443 </dev/null | sed -n -e '/-.BEGIN/,/-.END/ p' > example.pem
	@#curl --cacert example.pem https://example.com:8443
	@#w3m -dump https://example.com:8443
	@#echo && $(DASH)
	@#w3m -dump -o ssl_verify_server=false https://example.com:8443
	@#$(DASH)
	@#w3m -dump_both -o ssl_verify_server=false https://example.com:8443
	@$(DASH)

