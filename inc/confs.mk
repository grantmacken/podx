###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy-conf volume
#
ConfList   := $(filter-out src/proxy/conf/reverse_proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/reverse_proxy.conf
BuildConfs := build/proxy/conf/mime.types $(patsubst src/%.conf,build/%.conf,$(ConfList))
CheckConfs := $(patsubst src/%.conf,checks/%.conf,$(filter-out src/proxy/conf/self_signed.conf, $(ConfList)))
SiteConfs := $(patsubst src/%.conf,/opt/%.conf,$(ConfList))

.PHONY: confs confs-check confs-deploy
confs: $(BuildConfs)
confs-check: $(CheckConfs)
confs-deploy: deploy/proxy-conf.tar #  after confs-check

.PHONY: watch-confs
watch-confs:
	@while true; do \
        clear && $(MAKE) --silent confs; \
        inotifywait -qre close_write . || true; \
    done

deploy/proxy-conf.tar: $(CheckConfs) build/proxy/conf/mime.types
	@echo '##[  $(notdir $@) ]##'
	@podman volume export  $(basename $(notdir $@)) > $@
	@gcloud compute scp $@ $(GCE_NAME):/home/core/$(notdir $@)
	@#$(Gcmd) 'sudo podman run --rm --mount $(MountProxyConf) --entrypoint "[\"sh\",\"-c\"]" $(ALPINE) "rm -fv /opt/proxy/conf/*"'
	@$(Gcmd) 'sudo podman volume import $(basename $(notdir $@)) /home/core/$(notdir $@)'
	@$(Gcmd) 'sudo podman run --rm --mount $(MountProxyConf) --entrypoint "[\"sh\",\"-c\"]" $(ALPINE) \
			"ls -l /opt/proxy/conf/"'

.PHONY: confs-deploy-check
confs-deploy-check:
	@#$(Gcmd) 'ps -eZ | grep container_t'
	@$(Gcmd) 'sudo podman volume inspect proxy-conf' | jq '.'
	@$(Gcmd) 'sudo ls -ldZ /var/lib/containers/storage/volumes/proxy-conf/_data'
	@$(Gcmd) 'sudo ls -lRZ /var/lib/containers/storage/volumes/proxy-conf/_data'

.phony: confs-clean
confs-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildConfs)
	@#rm -fv deploy/proxy-conf.tar
	@#podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) 'rm -fv $(SiteConfs)' || true

.PHONY: confs-list
confs-list:
	@echo '## $(@) ##'
	@podman run  --rm --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'ls -al /opt/proxy/conf' || true
	@$(DASH)
	@echo ' - check the self_signed.conf'
	@podman run --rm --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat /opt/proxy/conf/self_signed.conf' || true
	@$(DASH)
	@podman run --rm --mount $(MountCerts) --entrypoint  '["sh", "-c"]' $(ALPINE) \
		'ls -al /opt/proxy/certs' || true

build/proxy/conf/%.conf: src/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $@ ]##'
	@cat $< | podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls /opt/proxy/conf/$(notdir $<)' > $@
	@if podman ps -a | grep -q $(OR)
	then
	  if podman exec or ls /opt/proxy/conf/reverse_proxy.conf &>/dev/null
	  then
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -s reload
		fi
	fi

checks/proxy/conf/%.conf: build/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $@ ]##'
	@podman run --interactive --rm  \
		--mount $(MountProxyConf) \
		--mount $(MountCerts) \
		--entrypoint '["sh", "-c"]' $(OPENRESTY) \
		'openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t'

build/proxy/conf/mime.types: src/proxy/conf/mime.types
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf)  --entrypoint '["sh", "-c"]' $(ALPINE) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls -l /opt/proxy/conf/$(notdir $<)' > $@

