###########################
### XQUERY CODE ###
# xquery main modules put into *xqerl-compiled-code* volume
# files are xQuery *library modules* except
# the restXQ files which can be a main modules?
###########################
CodeLibraryModules  :=  $(filter-out src/code/example.com.xqm ,$(wildcard src/code/*.xqm))  src/code/example.com.xqm
BuildLibCode := $(patsubst src/%,build/%,$(CodeLibraryModules))

# CodeMainModules  :=  $(wildcard src/code/*.xq)
# BuildMainCode := $(patsubst src/%,build/%,$(CodeMainModules))

PHONY: code
code: $(BuildLibCode) deploy/code.tar # deploy/xqerl-compiled-code.tar

.PHONY: watch-code
watch-code:
	@while true; do \
        clear && $(MAKE) --silent code 2>/dev/null || true; \
        inotifywait -qre close_write ./src/code || true; \
    done

PHONY: code-view
code-view:
	@$(DASH) && echo
	@w3m -dump -o ssl_verify_server=false https://example.com:8443
	@$(DASH)

.PHONY: watch-code-view
watch-code-view:
	@while true; do \
        clear && $(MAKE) --silent code-view 2>/dev/null || true; \
        inotifywait -qre close_write ./build/code || true; \
    done

.phony: code-clean
code-clean:
	@echo '## $(@) ##'
	@rm -v $(BuildLibraryModules) || true
	@rm -v deploy/xqerl-compiled-code.tar || true
	@podman run --interactive --rm  --mount $(MountCode) --entrypoint "sh" $(XQERL_IMAGE) \
		-c 'echo -n "container xq: " && rm -v ./code/src/*' || true

.PHONY: code-list
code-list:
	@echo '## $(@) ##'
	@podman run --pod $(POD) --interactive --rm  --mount $(MountCode) --entrypoint "sh" $(XQERL_IMAGE) \
		-c 'ls -al ./code/src'

build/code/%.xqm: src/code/%.xqm
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $<) ##'
	@# container xq server must be running
	@if xq compile $< | grep ':E:' 
	then
	false
	fi
	@cp $< $@

build/code/%.xq: src/code/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $<) ##'
	@# container xq server must be running
	@if xq compile $< | grep ':E:' 
	then
	false
	fi
	@cp $< $@

deploy/code.tar:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run  --interactive --rm  --mount $(MountCode)  \
	 --entrypoint "tar" $(XQERL_IMAGE) -czf - $(XQERL_HOME)/code 2>/dev/null > $@
