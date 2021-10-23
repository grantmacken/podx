###########################
### XQUERY CODE ###
# xquery main modules put into *xqerl-compiled-code* volume
# files are xQuery *library modules* except
###########################
CodeLibraryModules  :=  $(filter-out src/code/example.com.xqm ,$(wildcard src/code/*.xqm))  src/code/example.com.xqm
BuildLibCode := $(patsubst src/%.xqm,build/%.xqm.txt,$(CodeLibraryModules))

CodeMainModules  :=  $(wildcard src/code/*.xq)
BuildMainCode := $(patsubst src/%.xq,build/%.xq.txt,$(CodeMainModules))

PHONY: code # compile all xQuery library modules files in src/code
code: deploy/xqerl-code-source.tar

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
	@rm -v $(BuildLibCode)  $(BuildMainCode) || true
	@rm -v deploy/xqerl-compiled-code.tar || true
	@#podman run --interactive --rm  --mount $(MountCode) --entrypoint "sh" $(XQ) -c 'echo -n "container xq: " && rm -v ./code/src/*' || true

.PHONY: code-volume-list
code-volume-list:
	@echo '## $(@) ##'
	@podman run --rm  --mount $(MountCode) --entrypoint '["sh","-c"]' $(XQ) \
		'ls -al ./code/src'

.PHONY: code-library-list
code-library-list:
	@echo '## $(@) ##'
	if podman inspect --format="{{.State.Running}}" xq &>/dev/null
	then
	@podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].' | jq '.'
	fi

build/code/%.xqm.txt: src/code/%.xqm
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $<) ]##'
	if podman inspect --format="{{.State.Running}}" xq &>/dev/null
	then
	@bin/xq compile $< | tee $@
	@grep -q ':I:' $@ &>/dev/null
	fi

build/code/%.xq.txt: src/code/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $<) ##'
	@# container xq server must be running
	@bin/xq compile $< | tee $@
	@echo
	@if cat $< | grep -q ':E:' 
	then
	rm $@
	false
	fi

deploy/xqerl-code-source.tar: $(BuildLibCode) $(BuildMainCode)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run  --interactive --rm  --mount $(MountCode)  \
	 --entrypoint "tar" $(XQ) -czf - /usr/local/xqerl/code/src 2>/dev/null > $@
