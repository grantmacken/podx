###########################
### NGINX CONFIGURATION ###
###########################
PROXY_CONF := /opt/proxy/conf
ConfList   := $(filter-out src/proxy/conf/reverse-proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/reverse_proxy.conf
BuildConfs := $(patsubst src/%.conf,build/%.conf,$(ConfList))

.PHONY: confs
confs: build/proxy/conf/mime.types $(BuildConfs)

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
	@#podman run --pod $(POD) --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) -c 'rm -v /opt/proxy/conf/*'

.PHONY: confs-list
confs-list:
	@echo '## $(@) ##'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		-c 'ls -al /opt/proxy/conf'
	@echo ' - also check the certs volume'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		-c 'cat /opt/proxy/conf/self-signed.conf'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'ls -al /opt/proxy/certs'

build/proxy/conf/%.conf: src/proxy/conf/%.conf
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $@ ##'
	@#cat $<
	@# back up into build dir
	@podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		 -c 'cat /opt/proxy/conf/$(notdir $<) 2>/dev/null || echo ""' > $@
	@cat $< | podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		 -c 'cat - > /opt/proxy/conf/$(notdir $<)'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountProxyConf) --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		 -c 'openresty -p /opt/proxy/ -c /opt/proxy/conf/reverse_proxy.conf -t'

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

