SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -O globstar -eu -o pipefail -c
.DELETE_ON_ERROR:
# invoke with alias mk 
include .env
PROXY_IMAGE=proxy
# OPM_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(PROXY_NAME):opm-$(PROXY_VER)
#RESTY_IMAGE=$(GHPKG_REGISTRY)/$(REPO_OWNER)/$(PROXY_NAME):resty-$(PROXY_VER)
XQERL_IMAGE=xqerl
# proxy mounts
MountLetsencrypt := type=volume,target=/etc/letsencrypt,source=letsencrypt
MountCerts := type=volume,target=/opt/proxy/certs,source=certs
MountProxyConf   := type=volume,target=/opt/proxy/conf,source=proxy-conf
MountLualib := type=volume,target=$(OPENRESTY_HOME)/site/lualib,source=lualib
MountAssets := type=volume,target=/opt/proxy/html,source=static-assets
# xqerl mounts
MountCode   := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData   := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
#MountEscripts   := type=volume,target=$(XQERL_HOME)/bin/scripts,source=xqerl-escripts
# container path roots
W3M := podman run --pod $(POD) --interactive --rm  localhost/w3m
DASH = printf %60s | tr ' ' '-' && echo

.PHONY: help
help: ## show this help	
	@cat $(MAKEFILE_LIST) | 
	grep -oP '^[a-zA-Z_-]+:.*?## .*$$' |
	sort |
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

include inc/*.mk

CURL_IMAGE := docker.io/curlimages/curl:latest
#CONNECT_TO := --connect-to $(XQ):80:xq.$(NETWORK):$(XQERL_PORT) 
#RESOLVE := --resolve $(XQ):$(XQERL_PORT):$(ipAddress)
#CURL := docker run --pod $(POD) --rm --interactive  $(CURL_IMAGE) $(CONNECT_TO)

.PHONY: crl
crl: 
	podman run --pod $(POD) --rm --interactive  $(CURL_IMAGE) -v http://localhost:8081/example.com/home/index
	podman run --pod $(POD) --rm -it  localhost/w3m -dump_extra http://localhost:8081/example.com/home/index
	podman run --pod $(POD) --rm -it  localhost/w3m -dump http://localhost:8081/example.com/home/index

.PHONY: check
check: 
	@#podman ps --pod
	@#echo && echo 'check: example.com reachable on localhost'
	@#echo && $(DASH) && echo
	@#w3m -dump_head http://example.com:8080
	@#$(DASH) && echo
	@#w3m -dump https://example.com:8443
	@#curl -vk https://example.com:8443 || true
	@#$(DASH) && echo
	@#$(DASH) && echo
	@#curl -vkL http://example.com:8080 || true
	@#$(DASH) && echo
	@#openssl s_client -showcerts -connect example.com:8443 </dev/null | sed -n -e '/-.BEGIN/,/-.END/ p' > example.pem
	@#curl --cacert example.pem https://example.com:8443
	@#w3m -dump https://example.com:8443
	@echo && $(DASH)
	@w3m -dump -o ssl_verify_server=false https://example.com:8443
	@$(DASH)
	@w3m -dump_both -o ssl_verify_server=false https://example.com:8443
	@$(DASH)

