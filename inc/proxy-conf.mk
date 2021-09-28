###########################
### NGINX CONFIGURATION ###
###########################
PROXY_CONF := $(PROXY_PREFIX)/conf
ConfList   := $(filter-out src/proxy/conf/proxy.conf , $(wildcard src/proxy/conf/*.conf)) src/proxy/conf/proxy.conf
BuildConfs := $(patsubst src/%.conf,build/%.conf,$(ConfList))

.PHONY: confs
confs: deploy/proxy-conf.tar

.PHONY: watch-confs
watch-confs:
	@while true; do \
        clear && $(MAKE) --silent confs; \
        inotifywait -qre close_write . || true; \
    done

.phony: proxy-clean
proxy-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildConfs)
	@rm -fv deploy/nginx-configuration.tar

.PHONY: proxy-list
proxy-list:
	@echo '## $(@) ##'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(PROXY_IMAGE) \
		-c 'ls -al /opt/proxy/conf'

build/proxy/conf/%: src/proxy/conf/%
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@[ -d $(dir .tmp) ] || mkdir -p $(dir .tmp)
	@echo '## $@ ##'
	@podman run  --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(PROXY_IMAGE) \
		 -c 'cat $(PROXY_CONF)/$(*) 2>/dev/null || echo ""' > .tmp/$(*)
	@cat $< | podman run  --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(PROXY_IMAGE) \
		 -c 'cat - > $(PROXY_CONF)/$(*)'
	@if podman run  --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(PROXY_IMAGE) \
		 -c 'openresty -p $(PROXY_PREFIX)/ -c $(PROXY_CONF)/proxy.conf -t'  
	@then
	@rm .tmp/$(*)
	@cp $< $@
	@podman exec or openresty -p $(PROXY_PREFIX)/ -c $(PROXY_CONF)/proxy.conf -s reload  
	@else
	@cat .tmp/$(*) | podman run  --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(PROXY_IMAGE) \
		 -c 'cat - > $(PROXY_CONF)/$(*)'
	@fi

deploy/proxy-conf.tar: $(BuildConfs)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#echo ' - tar the "nginx-confguration" volume into deploy directory'
	@podman run  --interactive --rm  --mount $(MountProxyConf)  \
	 --entrypoint "tar" $(PROXY_IMAGE) -czf - $(PROXY_CONF) 2>/dev/null > $@

