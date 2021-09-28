
#####################
# make clean
# make pods
# make service-files
# - check the files
#   we want xqerl service to start before proxy service
#   after service started, check application all started then compile modules
#   the proxy service started after xqerl modules compiled
#####################
.PHONY: pods
pods: vol podx xq or
	@podman image list
	@podman volume list
	@podman pod list
	@podman ps -a --pod

.PHONY: pull
pull:
	@podman pull $(PROXY_IMAGE) && podman pull $(XQERL_IMAGE)
	@podman pull docker.io/curlimages/curl
	@podman image list

.PaaHONY: pull-helpers
pull-helpers:
	@podman pull ghcr.io/grantmacken/podx-zopfli:$(GHPKG_ZOPFLI_VER)
	@podman pull ghcr.io/grantmacken/podx-w3m:$(GHPKG_W3M_VER)
	@podman pull ghcr.io/grantmacken/podx-xqerl:$(GHPKG_XQ_VER)

# TODO use certs for letsencrypt
.PHONY: vol
vol:
	@podman volume exists static-assets || podman volume create static-assets
	@podman volume exists proxy-conf || podman volume create proxy-conf
	@podman volume exists letsencrypt || podman volume create letsencrypt
	@podman volume exists certs || podman volume create certs
	@podman volume exists lualib || podman volume create lualib
	@podman volume exists xqerl-database || podman volume create xqerl-database
	@podman volume exists xqerl-compiled-code || podman volume create xqerl-compiled-code

.PHONY: podx
podx: # --publish 80:80 --publish 443:443
	@echo "#(: $(@) :)#"
	@# only open port 8080 and 8433  
	@# or is reverse proxy for xq on port 8081
	@# curl and w3m which attached to pod can communicate with xq on port 8081
	@podman pod exists $(@) || podman pod create -p 8080:80 -p 8443:443 --name $(@)
	@podman pod list

.PHONY: xq # in podx listens on port 8081/tcp 
xq: 
	@echo "#(: $(@) :)#"
	@podman pod exists $(@) || podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name $(@) \
		--detach $(XQERL_IMAGE)
	@sleep 3
	@# TODO compile all library modules in src
	@xq compile src/code/example.com.xqm
	@echo
	@sleep 1

.PHONY: or # in podx listens on 80/tcp port. As podx exposes that port as 8080/tcp in the host, you can reach the app
or: 
	@echo "#(: $(@) :)#"
	@podman pod exists $(@) || podman run --pod $(POD) \
    --mount $(MountCerts) --mount $(MountProxyConf) --mount $(MountAssets) \
		--name $(@) \
    --detach $(PROXY_IMAGE)

.PHONY: pods-clean
pods-clean:
	@podman pod stop -a || true
	@podman pod rm $(POD) || true
	@systemctl --user disable pod-podx.service || true
	@systemctl --user disable container-or.service || true
	@systemctl --user disable container-xq.service || true
	@rm -f $(HOME)/.config/systemd/user/pod-podx.service
	@rm -f $(HOME)/.config/systemd/user/container-xq.service 
	@rm -f $(HOME)/.config/systemd/user/container-or.service 
	@systemctl --user daemon-reload
	@rm -f pod-podx.service
	@rm -f container-xq.service 
	@rm -f container-or.service 

.PHONY: vol-clean
vol-clean: clean
	@podman volume exists static-assets && podman volume rm static-assets
	@podman volume exists proxy-conf && podman volume rm proxy-conf
	@podman volume exists letsencrypt && podman volume rm letsencrypt
	@podman volume exists lualib && podman volume rm lualib
	@podman volume exists xqerl-database && podman volume rm xqerl-database
	@podman volume exists xqerl-compiled-code && podman volume rm xqerl-compiled-code
	@podman volume ls

.PHONY: service
service: 
	@mkdir -p $(HOME)/.config/systemd/user
	@rm -f *.service
	@podman generate systemd --files --name $(POD) 
	@sleep 1
	@cat pod-podx.service | 
	tee $(HOME)/.config/systemd/user/pod-podx.service
	@cat container-xq.service | 
	sed "19 i ExecStartPost=/bin/sleep 3" |  
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'xqerl:compile(\"code/src/view.xqm\").'" |
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'" |
	sed "19 i ExecStartPost=/bin/sleep 3" |
	tee $(HOME)/.config/systemd/user/container-xq.service
	@cat container-or.service | 
	sed 's/After=pod-podx.service/After=container-or.service/g' |
	tee $(HOME)/.config/systemd/user/container-or.service
	ls -al $(HOME)/.config/systemd/user
	@systemctl --user daemon-reload
	@systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service 
	@systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service 
	@systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service 
	@#reboot


