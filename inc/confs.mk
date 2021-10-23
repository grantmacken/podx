###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy-conf volume
#
ConfList   := $(filter-out src/proxy/conf/reverse_proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/reverse_proxy.conf
BuildConfs := build/proxy/conf/mime.types $(patsubst src/%.conf,build/%.conf,$(ConfList))
CheckConfs := $(patsubst src/%.conf,check/%.conf,$(filter-out src/proxy/conf/self_signed.conf, $(ConfList)))
SiteConfs := $(patsubst src/%.conf,/opt/%.conf,$(ConfList))

.PHONY: confs
confs: $(BuildConfs)

.PHONY: confs-check
confs-check: $(CheckConfs)

.PHONY: watch-confs
watch-confs:
	@while true; do \
        clear && $(MAKE) --silent confs; \
        inotifywait -qre close_write . || true; \
    done

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
	@if podman inspect --format="{{.State.Running}}" or &>/dev/null
	then
	  if podman exec or ls /opt/proxy/conf/reverse_proxy.conf &>/dev/null
	  then
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t
	  podman exec or openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -s reload
		fi
	fi


check/proxy/conf/%.conf: build/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $@ ]##'
	@podman run --interactive --rm  \
		--mount $(MountProxyConf) \
		--mount $(MountCerts) \
		--entrypoint '["sh", "-c"]' $(OPENRESTY) \
		'openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t'

build/proxy/conf/mime.types: src/proxy/conf/mime.types
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[  $@ ]##'
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf)  --entrypoint '["sh", "-c"]' $(ALPINE) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && ls -l /opt/proxy/conf/$(notdir $<)' > $@

deploy/proxy-conf.tar: build/proxy/conf/mime.types $(BuildConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#echo ' - tar the "nginx-confguration" volume into deploy directory'
	@podman run  --interactive --rm  --mount $(MountProxyConf)  \
	 --entrypoint "tar" $(OPENRESTY) -czf - /opt/proxy/conf 2>/dev/null > $@

