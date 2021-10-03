###########################
### commonmark content ###
###########################
MarkdownList  :=  $(wildcard src/data/*/content/*/*.md)
TemplateList  :=  $(wildcard src/data/*/content/*/*.xq)
DataMapList      :=  $(wildcard src/data/*/content/*/*.json) $(wildcard src/data/*/content/*.json)

BuildMarkdown := $(patsubst src/%.md,build/%.cmark.txt,$(MarkdownList))
BuildTemplate := $(patsubst src/%.xq,build/%.tpl.txt,$(TemplateList))
BuildDataMap  := $(patsubst src/%.json,build/%.map.txt,$(DataMapList))
# build/html/%.html: build/data/%.cmark.txt
PHONY: content
content: $(BuildMarkdown) # $(BuildTemplate) $(BuildDataMap)
PHONY: content-tar
content-tar: deploy deploy/xqerl-database.tar

.PHONY: watch-content
watch-content:
	@while true; do \
        clear && $(MAKE) --silent content 2>/dev/null || true; \
        inotifywait -qre close_write ./src/data/$(DOMAIN)/content/ || true; \
    done

CONTENT := home/articles/reverse-proxy-setup

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
	@#TODO content items belong to a db URI collection  e.g. http://example.com/content
	@# delete the db URI and all the content data is removed
	@read -p 'enter site domain name: (domain) ' -e -i 'example.com' domain
	@bin/xq delete collection $${domain}/content

.PHONY: content-list
content-list:
	@echo '## $(@) ##'
	@xq list $(DOMAIN)/content

build/data/%.cmark.txt: src/data/%.md
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@[ -d .tmp ] || mkdir -p .tmp
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@
	@grep -q 'XDM item: document-node' $@

xcxcxcxxc:
ifndef GITHUB_ACTIONS
	@POD_URI=http://localhost:8081/$(patsubst src/data/%.md,%,$<)
	@echo "Internal Pod Page URL: $$POD_URI"
	@#podman run --pod $(POD) --rm $(W3M) -dump_source -o accept_encoding='identity;q=0' $$URI
	@$(DASH)
	@podman run --pod $(POD) --rm $(W3M) -dump $$POD_URI
	@echo && $(DASH)
	@[ -e .tmp/example.com.pem ] \
    || openssl s_client -showcerts -connect example.com:8443 </dev/null \
		| sed -n -e '/-.BEGIN/,/-.END/ p' > .tmp/example.com.pem
	@$(DASH)
	@curl  -s -D - -o /dev/null --cacert .tmp/example.com.pem https://example.com:8443/$(patsubst src/data/example.com/content/%.md,%,$<)
	@$(DASH)
	@echo https://example.com:8443/$(patsubst src/data/example.com/content/%.md,%,$<)
	@$(DASH)
endif

build/data/%.map.txt: src/data/%.json
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@
	@grep -q 'XDM item: map' $@

build/data/%.tpl.txt: src/data/%.xq
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir  $<) ##'
	@bin/xq put $< | tee $@
	@grep -q 'XDM item: function' $@

deploy/xqerl-database.tar:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run  --interactive --rm  --mount $(MountData)  \
	 --entrypoint "tar" $(ALPINE) -czf - /usr/local/xqerl/data 2>/dev/null > $@
