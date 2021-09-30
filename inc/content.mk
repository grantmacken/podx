###########################
### commonmark content ###
###########################
MarkdownList  :=  $(wildcard src/data/*/content/*/*.md)
TemplateList  :=  $(wildcard src/data/*/content/*/*.xq)
DataMapList      :=  $(wildcard src/data/*/content/*/*.json)

BuildMarkdown := $(patsubst src/%.md,build/%.cmark.txt,$(MarkdownList))
BuildTemplate := $(patsubst src/%.xq,build/%.tpl.txt,$(TemplateList))
BuildDataMap  := $(patsubst src/%.json,build/%.map.txt,$(DataMapList))
BuiltHTML     := $(patsubst build/data/%.cmark.txt,build/html/%.html,$(BuildMarkdown))
# build/html/%.html: build/data/%.cmark.txt
PHONY: content
content: $(BuildTemplate) $(BuildDataMap) $(BuildMarkdown)

# $(BuildMarkdown) $(BuildDataMap) $(BuildTemplate)
xxxxx:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $@) ##'
	@echo '## $(dir  $@) ##'
	@echo 'directory: $(dir $(patsubst build/html/%.html,%,$@))'
	@#podman run --pod $(POD) --rm --mount $(MountAssets) $(ALPINE) ls -alR .
	@#podman run --pod $(POD) --rm $(W3M) -dump_source -o accept_encoding='identity;q=0' http://localhost:8081/$(patsubst build/html/%.html,%,$@) |
	@#cat $@ | podman run --pod $(POD) --rm --interactive $(W3M) -T text/html -dump

PHONY: content-tar
content-tar: deploy deploy/xqerl-database.tar

.PHONY: watch-content
watch-content:
	@while true; do \
        clear && $(MAKE) --silent content 2>/dev/null || true; \
        inotifywait -qre close_write ./src/data/$(DOMAIN)/content/ || true; \
    done

CONTENT := home/index

PHONY: content-view
content-view:
	@$(DASH) && echo
	@podman run --pod $(POD) --rm -i $(W3M) -dump http://localhost:8081/$(DOMAIN)/content/$(CONTENT)
	@$(DASH)

.PHONY: watch-content-view
watch-content-view:
	@while true; do \
        clear && $(MAKE) --silent content-view 2>/dev/null || true; \
        inotifywait -qre close_write ./build/data/$(DOMAIN)/content/ || true; \
    done

.phony: content-clean
content-clean:
	@echo '## $(@) ##'
	@rm -v $(BuildMarkdown) $(BuildTemplate) $(BuildDataMap) || true

.PHONY: content-list
content-list:
	@echo '## $(@) ##'
	@xq list $(DOMAIN)/content

build/data/%.cmark.txt: src/data/%.md
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@
	@URI=http://localhost:8081/$(patsubst src/data/%.md,%,$<)
	@echo "Page URL: $$URI"
	@#podman run --pod $(POD) --rm $(W3M) -dump_source -o accept_encoding='identity;q=0' $$URI
	@$(DASH)
	@podman run --pod $(POD) --rm $(W3M) -dump $$URI
	@echo && $(DASH)
	@#podman run --pod $(POD) --rm --mount $(MountAssets) $(ALPINE) mkdir -p $(patsubst src/data/%/$(notdir $<),%,$<)
	@#podman run --pod $(POD) --rm --mount $(MountAssets) $(ALPINE) ls -alR .


build/data/%.map.txt: src/data/%.json
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@

build/data/%.tpl.txt: src/data/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@

deploy/xqerl-database.tar:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run  --interactive --rm  --mount $(MountData)  \
	 --entrypoint "tar" $(ALPINE) -czf - /usr/local/xqerl/data 2>/dev/null > $@
