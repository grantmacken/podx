
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
pods: volumes podx xq or
	@podman image list
	@podman volume list
	@podman pod list
	@podman ps -a --pod

.PHONY: pull
pull: pods-pull-essential pods-pull-helpers

.PHONY: pods-pull-essential
pods-pull-essential:
	@podman pull $(ALPINE)
	@podman pull $(OPENRESTY)
	@podman pull $(OR)
	@podman pull $(XQ)

.PHONY: pods-pull-helpers
pods-pull-helpers:
	@podman pull $(CMARK)
	@podman pull $(MAGICK)
	@podman pull $(ZOPFLI)
	@podman pull $(CSSNANO)
	@podman pull $(WEBPACK)
	@podman pull $(W3M)
	@podman pull $(CURL)
	@podman image list

# TODO use certs for letsencrypt
.PHONY: volumes
volumes:
	@podman volume exists static-assets || podman volume create static-assets
	@podman volume exists proxy-conf || podman volume create proxy-conf
	@#podman volume exists letsencrypt || podman volume create letsencrypt
	@podman volume exists certs || podman volume create certs
	@podman volume exists lualib || podman volume create lualib
	@podman volume exists xqerl-database || podman volume create xqerl-database
	@podman volume exists xqerl-code || podman volume create xqerl-code
	@podman volume ls

.PHONY: podx
podx: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ##]"
	@# only open port 8080 and 8433  
	@# or is reverse proxy for xq on port 8081
	@# curl and w3m which attached to pod can communicate with xq on port 8081
	@podman pod exists $(@) || podman pod create -p 8080:80 -p 8443:443 --name $(@)
	@podman pod list

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	@echo "##[ $(@) ]##"
	@if podman inspect --format="{{.State.Running}}" xq &>/dev/null
	@then
	@bin/xq eval 'application:ensure_all_started(xqerl).'
	@else
	@podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name xq \
		--detach $(XQ)
	@sleep 2
	@bin/xq eval 'application:ensure_all_started(xqerl).'
	@fi
	@# after xq is up then compile code 
	@# $(MAKE) code

.PHONY: check-xq-up
check-xq-up:
	@podman run --rm --pod $(POD) $(W3M) -dump_head http://localhost:8081
	@#podman run --rm --pod $(POD) $(W3M) -dump_source http://localhost:8081
	@podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081
	@podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/example.com/content/home/index
	@podman run --rm --pod $(POD) $(W3M) -dump_head http://localhost:8081/example.com/

.PHONY: xq-down
xq-down: code-clean
	@echo "##[ $(@) ]##"
	@podman stop xq
	@podman rm xq

.PHONY: or-up # 
or-up: certs confs
	@echo "##[ $(@) ]##"
	@podman inspect --format="{{.State.Running}}" or &>/dev/null || \
		podman run --pod $(POD) \
		--mount $(MountCerts) --mount $(MountProxyConf) --mount $(MountAssets) \
		--name or \
		--detach $(OR)
	@$(MAKE) --silent certs-pem
	@podman ps -a --pod

.PHONY: or-reload
or-reload:
	@echo "##[ $(@) ]##"
	@podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t
	@podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -s reload
	@podman ps -a --pod

.PHONY: or-down
or-down:
	@echo "##[ $(@) ]##"
	@podman stop or || true
	@podman rm or || true

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

.PHONY: volumes-clean
volumes-clean: pods-clean
	@podman volume exists static-assets && podman volume rm static-assets
	@podman volume exists proxy-conf && podman volume rm proxy-conf
	@podman volume exists certs && podman volume rm certs
	@podman volume exists letsencrypt && podman volume rm letsencrypt
	@podman volume exists lualib && podman volume rm lualib
	@podman volume exists xqerl-database && podman volume rm xqerl-database
	@podman volume exists xqerl-code && podman volume rm xqerl-code
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
	sed "19 i ExecStartPost=/bin/sleep 2" |  
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'xqerl:compile(\"code/src/example.com.xqm\").'" |
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'" |
	sed "19 i ExecStartPost=/bin/sleep 2" |
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



