
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
pods: xq-up or-up
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

.PHONY: gce-pull
gce-pull: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman pull $(ALPINE)'
	@$(Gcmd) 'sudo podman pull $(OR)'
	@$(Gcmd) 'sudo podman pull $(XQ)'
	@$(Gcmd) 'sudo podman pull $(CURL)'
	@$(Gcmd) 'sudo podman image list'

# TODO use certs for letsencrypt
.PHONY: volumes
volumes:
	@podman volume exists static-assets || podman volume create static-assets
	@podman volume exists proxy-conf || podman volume create proxy-conf
	@podman volume exists certs || podman volume create certs
	@podman volume exists lualib || podman volume create lualib
	@podman volume exists xqerl-database || podman volume create xqerl-database
	@podman volume exists xqerl-code || podman volume create xqerl-code
	@podman volume ls

.PHONY: gce-volumes
gce-volumes:
	@$(Gcmd) 'sudo podman volume create static-assets' || true
	@$(Gcmd) 'sudo podman volume create proxy-conf' || true
	@$(Gcmd) 'sudo podman volume create certs' || true
	@$(Gcmd) 'sudo podman volume create lualib' || true
	@$(Gcmd) 'sudo podman volume create xqerl-database' || true
	@$(Gcmd) 'sudo podman volume create xqerl-code' || true
	@$(Gcmd) 'sudo podman volume ls'

.PHONY: gce-volumes-clean
gce-volumes-clean:
	@$(Gcmd) 'sudo podman volume rm static-assets' || true
	@$(Gcmd) 'sudo podman volume rm  proxy-conf' || true
	@$(Gcmd) 'podman volume rm certs' || true
	@$(Gcmd) 'podman volume rm lualib' || true
	@$(Gcmd) 'sudo podman volume rm xqerl-database' || true
	@$(Gcmd) 'sudo podman rm create xqerl-code' || true
	@$(Gcmd) 'sudo podman volume prune -f '
	@$(Gcmd) 'sudo podman volume ls '

.PHONY: podx
podx: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ##]"
	@podman pod exists $(POD) || podman pod create -p 8080:80 -p 8443:443 --name $(@)
	@podman pod list

.PHONY: gce-podx
gce-podx: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman pod exists $(POD) || sudo podman pod create -p 80:80 -p 443:443 --name $(POD)'
	@$(Gcmd) 'sudo podman pod list'

.PHONY: xq-up # in podx listens on port 8081/tcp 
xq-up: podx
	@echo "##[ $(@) ]##"
	@podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name xq \
		--detach $(XQ)
	@sleep 2
	@bin/xq eval 'application:ensure_all_started(xqerl).'
	@# after xq is up then compile code 

.PHONY: gce-xq-up # in podx listens on port 8081/tcp 
gce-xq-up:
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman run --pod $(POD) \
		 --mount $(MountCode) --mount $(MountData) \
		 --name xq \
		--detach $(XQ)'
	@sleep 2
	@$(Gcmd) 'sudo podman exec xq xqerl eval "application:ensure_all_started(xqerl)."'
	@# after xq is up then we can check if cowboy server is listening on port 8081
	@$(Gcmd) 'sudo podman run --rm --pod $(POD) $(W3M) -dump_head http://localhost:8081'

.PHONY: xq-down
xq-down: #TODO use systemd instead
	@echo "##[ $(@) ]##"
	@if podman ps -a | grep -q $(XQ)
	then
	@podman stop xq
	@podman rm xq
	fi

.PHONY: or-up # 
or-up: certs confs confs-check
	@echo "##[ $(@) ]##"
	@podman run --pod $(POD) \
		--mount $(MountCerts) --mount $(MountProxyConf) --mount $(MountAssets) \
		--name or \
		--detach $(OR)
	@podman ps -a --pod

.PHONY: gce-or-up # 
gce-or-up:
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman run --pod $(POD) \
		--mount $(MountCerts) --mount $(MountProxyConf) --mount $(MountAssets) \
		--name or \
		--detach $(OR)'
	@$(Gcmd) 'sudo podman ps -a --pod'

.PHONY: gce-etc-hosts
gce-etc-hosts: # TODO once only
	@$(Gcmd) 'sudo echo "10.152.0.8   example.com" | sudo tee -a /etc/hosts'
	@#remove last line $(Gcmd) 'sudo sed -i '$$d' /etc/hosts'
	@$(Gcmd) 'cat /etc/hosts'

.PHONY: gce-or-up-check 
gce-or-up-check:
	@# W3M running in the pod
	@$(Gcmd) 'sudo podman run --rm --pod $(POD) $(W3M) -dump_head http://localhost:80' || true
	@$(Gcmd) 'sudo podman run --rm --pod $(POD) $(W3M) -dump http://localhost:80' || true
	@# W3M running on the gce host
	@$(Gcmd) 'sudo podman run --rm  $(W3M) -dump http://10.152.0.8:80' || true
	@$(Gcmd) 'sudo podman run --rm  $(W3M) -dump http://example.com' || true

.PHONY: gce-or-up-check-ssl 
gce-or-up-check-ssl:
	@# CURL running in the gce host
	@$(Gcmd) 'sudo podman run --rm  --mount $(MountCerts) $(CURL) \
		--cacert /opt/proxy/certs/example.com.pem \
		--silent \
		--show-error \
	  --connect-timeout 1 \
	  --max-time 2 \
		https://example.com/'
	@echo && $(DASH)
	@# W3M running in the gce host
	@$(Gcmd) 'sudo podman run --rm  --mount $(MountCerts) $(W3M) \
		-o ssl_ca_file=/opt/proxy/certs/example.com.pem \
		-dump_extra \
		https://example.com/'
	@echo && $(DASH)

.PHONY: or-reload
or-reload:
	@echo "##[ $(@) ]##"
	@podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t
	@podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -s reload
	@podman ps -a --pod

.PHONY: or-down
or-down: #TODO use systemd instead
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

.PHONY: gce-pods-clean
gce-pods-clean:
	@podman pod stop -a || true
	@podman pod rm $(POD) || true

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
	sed "19 i ExecStartPost=/bin/sleep 1" |  
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'xqerl:compile(\"code/src/routes.xqm\").'" |
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'" |
	sed "19 i ExecStartPost=/bin/sleep 2" |
	tee $(HOME)/.config/systemd/user/container-xq.service
	@cat container-or.service | 
	sed 's/After=pod-podx.service/After=pod-podx.service container-xq.service/g' |
	tee $(HOME)/.config/systemd/user/container-or.service
	ls -al $(HOME)/.config/systemd/user
	@systemctl --user daemon-reload
	@systemctl --user is-enabled container-xq.service &>/dev/null || systemctl --user enable container-xq.service 
	@systemctl --user is-enabled container-or.service &>/dev/null || systemctl --user enable container-or.service 
	@systemctl --user is-enabled pod-podx.service &>/dev/null || systemctl --user enable pod-podx.service 
	@#reboot

.PHONY: service-start
service-start: 
	@systemctl --user start container-xq.service
	@podman pod list
	@podman ps -a --pod
	@systemctl status --user -l --no-pager container-xq.service
	@podman top xq

.PHONY: service-stop
service-stop:
	@systemctl --user stop container-xq.service
	@podman pod list
	@podman ps -a --pod

.PHONY: service-status
service-status:
	@systemctl list-units --user  --type=service --state=active,running' | awk '/container.*\.service/ {print $1}
	@podman pod list
	@podman ps -a --pod
	@systemctl status --user -l --no-pager container-xq.service


.PHONY: gce-service
gce-service: 
	@$(Gcmd) 'sudo podman generate systemd --files --name $(POD)' 
	@$(Gcmd) 'cat pod-podx.service | sudo tee /etc/systemd/system/pod-podx.service'
	@$(Gcmd) 'cat container-or.service | 
	sed "s/After=pod-podx.service/After=pod-podx.service container-xq.service/g" |
	sudo tee /etc/systemd/system/container-or.service'
	@$(Gcmd) 'cat container-xq.service | 
	sed "19 i ExecStartPost=/bin/sleep 2" |  
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval \"xqerl:compile(\x27code/src/routes.xqm\x27).\"" |
	sed "19 i ExecStartPost=/usr/bin/podman exec xq xqerl eval \"application:ensure_all_started(xqerl).\"" |
	sed "19 i ExecStartPost=/bin/sleep 2" | sudo tee /etc/systemd/system/container-xq.service'
	@$(Gcmd) 'sudo systemctl daemon-reload'
	@$(Gcmd) 'sudo systemctl enable container-xq.service' || true
	@$(Gcmd) 'sudo systemctl enable container-or.service' || true
	@$(Gcmd) 'sudo systemctl enable pod-podx.service' || true

.PHONY: pods-stop
pods-stop:
	@podman pod list
	@podman ps -a --pod
	@podman pod stop -a || true
	@# podman pod rm $(POD) || true
	@podman pod list
	@podman ps -a --pod

.PHONY: gce-pods-stop
gce-pods-stop:
	@$(Gcmd) 'sudo podman pod list'
	@$(Gcmd) 'sudo podman ps -a --pod'
	@$(Gcmd) 'sudo podman pod stop -a' || true
	@#$(Gcmd) 'sudo podman pod rm $(POD)' || true
	@$(Gcmd) 'sudo podman pod list'
	@$(Gcmd) 'sudo podman ps -a --pod'

.PHONY: gce-pods-start
gce-pods-start:
	@#$(Gcmd) 'sudo systemctl list-units --type=service --state=running'
	@#$(Gcmd) 'sudo systemctl list-units --all' | grep podx
	@#$(Gcmd) 'sudo systemctl status pod-podx' || true 
	@#$(Gcmd) 'sudo systemctl status container-or' || true
	@#$(Gcmd) 'sudo systemctl status container-xq' || true
	@#$(Gcmd) 'sudo systemctl enabled pod-podx' || true 
	@#$(Gcmd) 'sudo systemctl enabled container-xq' || true 
	@#$(Gcmd) 'sudo systemctl start status container-xq' || true 
	@#$(Gcmd) 'sudo systemctl start container-xq.service' || true 
	@$(Gcmd) 'sudo systemctl start pod-podx.service' || true 
	@#$(Gcmd) 'sudo journalctl -xeu pod-podx.service' 
	@#$(Gcmd) 'sudo podman pod list'
	@#$(Gcmd) 'sudo podman ps -a --pod'

.PHONY: gce-pods-status
gce-pods-status:
	@$(Gcmd) 'sudo systemctl list-units --type=service --state=active,running' | awk '/container.*\.service/ {print $1}'
	@#$(Gcmd) 'sudo systemctl list-units --all' | grep podx
	@#$(Gcmd) 'sudo systemctl status pod-podx' || true 
	@#$(Gcmd) 'sudo systemctl status container-or' || true
	@#$(Gcmd) 'sudo systemctl status container-xq' || true
	@#$(Gcmd) 'sudo systemctl enabled pod-podx' || true 
	@#$(Gcmd) 'sudo systemctl enabled container-xq' || true 
	@#$(Gcmd) 'sudo systemctl start status container-xq' || true 
	@#$(Gcmd) 'sudo systemctl start container-xq.service' || true 
	@#$(Gcmd) 'sudo systemctl start pod-podx.service' || true 
	@#$(Gcmd) 'sudo journalctl -xeu pod-podx.service' 
	@#$(Gcmd) 'sudo journalctl -xeu container-xq.service' 
	@#$(Gcmd) 'sudo podman pod list'
