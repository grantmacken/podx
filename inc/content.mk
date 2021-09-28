###########################
### commonmark content ###
###########################
MarkdownList  :=  $(wildcard src/data/*/content/*/*.md)
TemplateList  :=  $(wildcard src/data/*/content/*/*.xq)
DataMapList      :=  $(wildcard src/data/*/content/*/*.json)

BuildMarkdown := $(patsubst src/%.md,build/%.cmark.txt,$(MarkdownList))
BuildTemplate  := $(patsubst src/%.xq,build/%.tpl.txt,$(TemplateList))
BuildDataMap := $(patsubst src/%.json,build/%.map.txt,$(DataMapList))

PHONY: content
content: $(BuildMarkdown) $(BuildTemplate) $(BuildDataMap)

.PHONY: watch-content
watch-content:
	@while true; do \
        clear && $(MAKE) --silent content 2>/dev/null || true; \
        inotifywait -qre close_write ./src/data/$(DOMAIN)/content/ || true; \
    done

PHONY: content-view
content-view:
	@$(DASH) && echo
	@podman run --pod $(POD) --rm -it  localhost/w3m -dump http://localhost:8081/$(DOMAIN)/content/home/index
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
	@xq put $< | tee $@

build/data/%.map.txt: src/data/%.json
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	xq put $< | tee $@

build/data/%.tpl.txt: src/data/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@xq put $< | tee $@
