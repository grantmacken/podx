###########################
### XQUERY CODE ###
# xquery main modules put into *xqerl-compiled-code* volume
# files are xQuery *library modules* except
###########################
CodeLibraryModules  :=  $(filter-out src/code/routes.xqm ,$(wildcard src/code/*.xqm))  src/code/routes.xqm
BuildLibCode := $(patsubst src/%.xqm,build/%.xqm.txt,$(CodeLibraryModules))
CodeMainModules  :=  $(wildcard src/code/*.xq)
BuildMainCode := $(patsubst src/%.xq,build/%.xq.txt,$(CodeMainModules))

PHONY: code # compile all xQuery library modules files in src/code
code: $(BuildLibCode) $(BuildMainCode)
code-deploy: deploy/xqerl-code.tar #  after xq-up and code
code-deploy-compile: $(patsubst build/%,deploy/%,$(BuildLibCode)) #  after code-deploy

.PHONY: watch-code
watch-code:
	@while true; do \
        clear && $(MAKE) --silent code 2>/dev/null || true; \
        inotifywait -qre close_write ./src/code || true; \
    done

.PHONY: watch-code-view
watch-code-view:
	@while true; do \
        clear && $(MAKE) --silent code-view 2>/dev/null || true; \
        inotifywait -qre close_write ./build/code || true; \
    done

deploy/xqerl-code.tar: $(BuildLibCode) $(BuildMainCode)
	@echo '## $(@) ##'
	@podman volume export  $(basename $(notdir $@)) > $@
	@gcloud compute scp $@ $(GCE_NAME):/home/core/$(notdir $@)
	@$(Gcmd) 'sudo podman volume import $(basename $(notdir $@)) /home/core/$(notdir $@)'
	@$(Gcmd) 'sudo podman run --rm --mount $(MountCode) --entrypoint "[\"sh\",\"-c\"]" $(ALPINE) \
			"ls -l /usr/local/xqerl/code/src"'

.phony: code-clean
code-clean:
	@echo '## $(@) ##'
	@rm -v $(BuildLibCode)  $(BuildMainCode) || true
	@rm -v deploy/xqerl-code.tar || true
	@podman run --rm  --mount $(MountCode) --entrypoint "[\"sh\",\"-c\"]" $(ALPINE) \
		'ls -lR /usr/local/xqerl/code' || true
	@podman run --rm  --mount $(MountCode) --entrypoint "[\"sh\",\"-c\"]" $(ALPINE) \
		'rm -v /usr/local/xqerl/code/src/*' || true

.PHONY: code-volume-list
code-volume-list:
	@echo '## $(@) ##'
	@podman run --rm  --mount $(MountCode) --entrypoint '["sh","-c"]' $(XQ) \
		'ls -al ./code/src'

.PHONY: code-library-list
code-library-list:
	@echo '## $(@) ##'
	@if podman ps -a | grep -q $(XQ)
	then
	podman exec xq xqerl eval '[binary_to_list(X) || X <- xqerl_code_server:library_namespaces()].' | jq '.'
	fi

build/code/%.xqm.txt: src/code/%.xqm
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $<) ]##'
	@if podman ps -a | grep -q $(XQ)
	then
	@bin/xq compile $< | tee $@
	@grep -q ':I:' $@ &>/dev/null
	@echo
	fi

deploy/code/%.xqm.txt: build/code/%.xqm.txt
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(basename $(notdir $<)) ]##'
	@if $(Gcmd) 'sudo podman ps -a' | grep -q $(XQ)
	then
	@$(Gcmd) 'sudo podman exec xq xqerl eval "xqerl:compile(\"code/src/$(basename $(notdir $<))\")."' > $@
	fi

build/code/%.xq.txt: src/code/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $<) ##'
	@if podman ps -a | grep -q $(XQ)
	then
	@bin/xq compile $< | tee $@
	@grep -q ':I:' $@ &>/dev/null
	@echo
	fi
