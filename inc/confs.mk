###########################
### NGINX CONFIGURATION ###
###########################
# files for the proxy-conf volume
#
ConfList   := $(filter-out src/proxy/conf/reverse_proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/reverse_proxy.conf
BuildConfs := $(patsubst src/%.conf,build/%.conf,$(ConfList))
SiteConfs := $(patsubst src/%.conf,check/%.conf,$(filter-out src/proxy/conf/self_signed.conf, $(ConfList)))

.PHONY: confs
confs: build/proxy/conf/mime.types $(BuildConfs)

.PHONY: confs-check
confs-check: $(SiteConfs)

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
	@rm -fv deploy/nginx-configuration.tar
	@podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) 'rm -fv '

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
	@echo '## $@ ##'
	@cat $< | podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		 'cat - > /opt/proxy/conf/$(notdir $<) && cat /opt/proxy/conf/$(notdir $<)' > $@

check/proxy/conf/%.conf: build/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $@ ##'
	@podman run --interactive --rm  \
		--mount $(MountProxyConf) \
		--mount $(MountCerts) \
		--entrypoint '["sh", "-c"]' $(OPENRESTY) \
		'openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t'

build/proxy/conf/mime.types: src/proxy/conf/mime.types
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $@ ##'
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		 -c 'cat - > /opt/proxy/conf/$(notdir $<)'
	@cp $< $@

deploy/proxy-conf.tar: $(BuildConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#echo ' - tar the "nginx-confguration" volume into deploy directory'
	@podman run  --interactive --rm  --mount $(MountProxyConf)  \
	 --entrypoint "tar" $(OPENRESTY) -czf - /opt/proxy/conf 2>/dev/null > $@

