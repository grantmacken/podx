######################
###  STATIC ASSETS ###
######################

IconsList := $(wildcard src/static_assets/icons/*.svg)
FontsList := $(wildcard src/static_assets/fonts/*.woff2)

BuildIcons := $(patsubst src/%.svg,build/%.txt,$(IconsList))
BuildFonts := $(patsubst src/%.woff2,build/%.txt,$(FontsList))


DomainStylesList := $(wildcard src/static_assets/$(DOMAIN)/styles/*.css)
CommonStylesList := $(wildcard src/static_assets/styles/*.css)

DomainBuildStyles := $(patsubst src/%.css,build/%.txt,$(DomainStylesList))

.PHONY: assets
assets: deploy/static-assets.tar

.PHONY: styles
styles: $(DomainBuildStyles)

.PHONY: fonts
fonts: $(BuildFonts)

.PHONY: watch-assets
watch-assets:
	@while true; do \
        clear && $(MAKE) --silent assets; \
        inotifywait -qre close_write . || true; \
    done

.PHONY: assets-clean
assets-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildIcons)
	@rm -fv $(DomainBuildStyles)
	@rm -fv deploy/static-assets.tar

.PHONY: styles-clean
styles-clean:
	@echo '## $(@) ##'
	@rm -fv $(DomainBuildStyles)

.PHONY: assets-check
assets-check:
	@echo '## $(@) ##'
	@$(DASH) 
	@podman run --pod $(POD) --interactive --rm  --mount $(MountAssets) \
		--entrypoint "sh" $(PROXY_IMAGE) -c 'ls -al /opt/proxy/html/icons'
	@curl -v http://example.com:8080/icons/article
	@echo && $(DASH) 

.PHONY: assets-list
assets-list:
	@echo '## $(@) ##'
	@podman run --interactive --rm --mount $(MountAssets) --workdir /opt/proxy/html \
		localhost/alpine 'ls -alR .'

# https://imagemagick.org/script/command-line-processing.php
# https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/
# TODO https://imagemagick.org/script/magick-script.php
.PHONY: images
images:  # TODO
	@#podman run --interactive --rm --mount $(MountAssets) localhost/magick pwd
	@#podman run --interactive --rm  --mount $(MountAssets) localhost/magick 'printenv'
	@#podman run --interactive --rm --mount $(MountAssets) localhost/magick 'rm -fv *.jpg'
	@cat src/static_assets/images/SampleJPGImage_50kbmb.jpg | \
		podman run --interactive --rm --mount $(MountAssets) localhost/magick \
		'magick jpg:-  \
		-filter Triangle \
		-define filter:support=2 \
		-thumbnail '180' \
		-unsharp 0.25x0.08+8.3+0.045 \
		-dither None \
		-posterize 136 \
		-quality 82 \
		-define jpeg:fancy-upsampling=off \
    -define png:compression-filter=5 \
		-define png:compression-level=9 \
		-define png:compression-strategy=1 \
		-define png:exclude-chunk=all \
		-interlace none -colorspace sRGB \
		-set filename:area '%wx%h' jpg:sample-%[filename:area].jpg'
	@#podman run --interactive --rm --mount $(MountAssets) localhost/magick ls -l
	
################
### STYLES ###
###  postcss cssnano autoprefix
################
build/static_assets/$(DOMAIN)/styles/%.txt: src/static_assets/$(DOMAIN)/styles/%.css
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run --interactive --rm  --mount $(MountAssets) --entrypoint "sh" localhost/proxy \
		-c 'mkdir -p /opt/proxy/html/$(DOMAIN)/styles'
	@cat $< \
		| podman run --interactive --rm localhost/cssnano --no-map --use cssnano \
		| podman run --interactive --rm localhost/zopfli \
		| podman run --interactive --rm  --mount $(MountAssets) --entrypoint "sh" localhost/proxy \
		-c 'cat - > /opt/proxy/html/$(DOMAIN)/styles/$(*).css.gz'

################
### SCRIPTS ###
### TODO webpack
################
build/static_assets/scripts/%.txt: src/static_assets/scripts/%.js
	@echo "##[ $< ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@bin/xq link $(DOMAIN) scripts/$(*).js | tee $@

###############
###  FONTS  ###
# these font are in the commons
# so can be used by any domain
###############

build/static_assets/fonts/%.txt: src/static_assets/fonts/%.woff2
	@echo "##[ $(notdir $<) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@cat $< | podman run --interactive --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' localhost/proxy \
		'cat - >  $(patsubst src/static_assets/%,html/%,$(<))'
	@echo '$(notdir $<)' > $@ 


sasasa:
		'mkdir -p /opt/proxy/html/fonts'


asasasasasll:
	@#podman run --interactive --rm  --mount $(MountAssets) localhost/alpine \
		'ls -l fonts'
#############
### ICONS ###
# these are in the commons
#############
build/static_assets/icons/%.txt: src/static_assets/icons/%.svg
	@echo "##[ $< ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@bin/xq link $(DOMAIN) icons/$(*).svg | tee $@

deploy/static-assets.tar: $(BuildIcons)
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - tar the "static-assets" volume into deploy directory'
	@podman run --interactive --rm --mount $(MountAssets)  \
		--entrypoint "tar" $(PROXY_IMAGE) -czf - $(PROXY_PREFIX)/html 2>/dev/null > $@
