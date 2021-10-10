######################
###  STATIC ASSETS ###
######################

DomainStylesList := $(wildcard src/static_assets/*/styles/*.css)
CommonStylesList := $(wildcard src/static_assets/styles/*.css)

IconsList := $(wildcard src/static_assets/icons/*.svg)
FontsList := $(wildcard src/static_assets/fonts/*.woff2)
JpegList :=  $(wildcard src/static_assets/images/*/*.jpg)
ScriptsList := $(wildcard src/static_assets/scripts/*.js)

BuildStyles := $(patsubst src/%,build/%.txt,$(DomainStylesList))
BuildFonts := $(patsubst src/%.woff2,build/%.txt,$(FontsList))
BuildImages := $(patsubst src/%.jpg,build/%.txt,$(JpegList))
SiteImages := $(patsubst src/static_assets/%,%,$(JpegList))

BuildIcons := $(patsubst src/%.svg,build/%.svgz.txt,$(IconsList))
SiteIcons := $(patsubst src/static_assets/%,/opt/proxy/html/%.svgz,$(IconsList))

BuildScripts := $(patsubst src/%,build/%.txt,$(ScriptsList)) # TODO webpack
SiteScripts := $(patsubst src/static_assets/%,/opt/proxy/html/%.gz,$(ScriptsList))

FileSize = $(shell ls -lh $1 | tr -s ' ' | cut -d ' ' -f 5)

.PHONY: assets
assets: deploy/static-assets.tar

.PHONY: styles
styles: $(BuildStyles)

.PHONY: fonts
fonts: $(BuildFonts)

.PHONY: icons
icons: $(BuildIcons)

.PHONY: images
images: $(BuildImages)

.PHONY: scripts
scripts: $(BuildScripts)

.PHONY: watch-assets
watch-assets:
	@while true; do \
        clear && $(MAKE) --silent assets; \
        inotifywait -qre close_write . || true; \
    done

.PHONY: assets-clean
assets-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildStyles)
	@rm -fv deploy/static-assets.tar
	@read -p 'enter site domain name: (domain) ' -e -i 'example.com' domain
	@podman run --rm --mount $(MountAssets) $(ALPINE) rm -rv $${domain}

.PHONY: assets-list
assets-list:
	@podman run  --rm --mount $(MountAssets) $(ALPINE) ls -alR fonts icons images

################
### STYLES ###
###  postcss cssnano autoprefix
################
build/static_assets/%.css.txt: src/static_assets/%.css
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run --rm --mount $(MountAssets) $(ALPINE) mkdir -p $(dir $*)
	@cat $< \
		| podman run --interactive --rm ${CSSNANO} --no-map --use cssnano \
		| podman run --interactive --rm ${ZOPFLI} \
		| podman run --interactive --rm  --mount $(MountAssets) --entrypoint "sh" $(ALPINE) \
	    -c 'cat - > /opt/proxy/html/$(*).css.gz'
	@cp $< $@

.PHONY: styles-clean
styles-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildStyles)
	@read -p 'enter site domain name: (domain) ' -e -i 'example.com' domain
	@podman run --rm --mount $(MountAssets) $(ALPINE) rm -f $${domain}/styles/*

.PHONY: styles-list
styles-list:
	@echo '## $(@) ##'
	@read -p 'enter site domain name: (domain) ' -e -i 'example.com' domain
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls $${domain}/styles

###############
###  FONTS  ###
# these font are in the commons
# so can be used by any domain
###############

build/static_assets/%.txt: src/static_assets/%.woff2
	@echo "##[ $(notdir $< ) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE) 'mkdir -p fonts'
	@cat $< | \
		podman run --interactive --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE)  \
		'cat - > ./fonts/$(notdir $< )'
	@echo ' - in static-asset volume: /opt/proxy/html/$(*).woff2' | tee $@
	@echo " - font size: $(call FileSize, $<)" | tee -a $@

.PHONY: fonts-list
fonts-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls fonts

#############
### ICONS ###
#############
# these are in the commons

build/static_assets/%.svgz: src/static_assets/%.svg
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo "SRC: [ $<  ]"
	@podman run --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE) 'mkdir -p icons'
	@podman run --rm --mount $(MountAssets) $(ALPINE) mkdir -p $(dir $*)
	@cat $< | \
    podman run --rm --interactive ${ZOPFLI} | \
		podman run --interactive --rm --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE)  \
		'cat - > $(*).svgz && cat $(*).svgz' > $@

build/static_assets/%.svgz.txt: build/static_assets/%.svgz
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo 'Static Asset: $(shell podman run --rm --mount $(MountAssets) --entrypoint '["sh", "-c"]' $(ALPINE) 'ls $(*).svgz')' | tee  $@
	@echo " Origin Size: $(call FileSize,src/static_assets/$(*).svg)" | tee -a $@
	@echo " Result Size: $(call FileSize, $<)" | tee -a $@

.PHONY: icons-list
icons-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls icons

.PHONY: icons-clean
icons-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildIcons)
	@podman run --rm --mount $(MountAssets) $(ALPINE) sh -c 'rm -fv $(SiteIcons)'

################
###  IMAGES  ###
################
# https://imagemagick.org/script/command-line-processing.php
# https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/
# TODO https://imagemagick.org/script/magick-script.php

ImageWidthFromDir=$(shell basename $(dir $1))
ImageOriginWidth=$(shell cat $1 \
								 | podman run --rm --interactive --entrypoint '["/bin/sh", "-c"]' $(MAGICK) \
								 "magick identify -format '%w' jpg:- ")

ImageOriginSize=$(shell cat $1 \
								| \podman run --rm --interactive --entrypoint '["/bin/sh", "-c"]' $(MAGICK)\
								"magick identify -format '%b' jpg:- ")

build/static_assets/%.txt: src/static_assets/%.jpg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo "SRC: [ $< ]"
	@echo "Orginal Width: [ $(call ImageOriginWidth, $<) ]"
	@echo "Aim For Width: [ $(call ImageWidthFromDir, $<) ]"
	@podman run --rm --mount $(MountAssets) $(ALPINE) mkdir -p $(dir $*)
	@cat $< | podman run --rm --interactive --entrypoint '["/bin/sh", "-c"]' $(MAGICK) \
		"magick jpg:-  \
		-filter Triangle \
		-define filter:support=2 \
		-thumbnail '$(call ImageWidthFromDir,$<)' \
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
		jpg:- " | \
		podman run --interactive --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE)  \
		'cat - > $(dir $*)$(notdir $<)'
	@echo    "Orginal Size:  [ $(call ImageOriginSize, $<) ]"
	@echo -n " Result Size:  [ "
	@podman run --rm --interactive --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(MAGICK) \
		'magick identify -format "%b" /opt/proxy/html/$(dir $*)$(notdir $<)'
	@echo -n " ] " && echo
	@podman run --rm --interactive --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(MAGICK) \
		'magick identify -verbose /opt/proxy/html/$(dir $*)$(notdir $<)' > $@
	@$(DASH)

.PHONY: images-list
images-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls -alR images

.PHONY: images-clean
images-clean:
	@echo '## $(@) ##'
	@rm -fv $(BuildImages)
	@podman run --rm --mount $(MountAssets) $(ALPINE) sh -c 'rm -fv $(SiteImages)'
	
################
### SCRIPTS ###
### TODO webpack
###############
#OnServerSize = $(shell  podman run --rm  --mount $(MountAssets) --entrypoint '["sh", "-c"]' $(ALPINE) \
	'ls -lh /opt/proxy/html/$(*).js.gz' | awk -F " " {'print $$5'})

build/static_assets/%.js.gz: src/static_assets/%.js
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run --rm --mount $(MountAssets) $(ALPINE) mkdir -p $(dir $*)
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls $(dir $*)
	@echo "SRC: [ $* ]"
	@cat $< \
		| podman run --interactive --rm ${ZOPFLI} \
		| podman run --interactive --rm --mount $(MountAssets) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > $(*).js.gz && cat $(*).js.gz' > $@

build/static_assets/%.js.txt: build/static_assets/%.js.gz
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo 'Static Asset: $(shell podman run --rm --mount $(MountAssets) --entrypoint '["sh", "-c"]' $(ALPINE) 'ls $(*).js.gz')' | tee  $@
	@echo " Origin Size: $(call FileSize,src/static_assets/$(*).js)" | tee -a $@
	@echo " Result Size: $(call FileSize, $<)" | tee -a $@


.PHONY: scripts-list
scripts-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) --entrypoint '["sh", "-c"]'  $(ALPINE) \
		'ls -alR ./scripts'

.PHONY: scripts-clean
scripts-clean:
	@echo '## $(@) ##'
	@rm -v $(BuildScripts) || true
	@podman run --rm --mount $(MountAssets) --entrypoint '["sh", "-c"]'  $(ALPINE) \
		'rm -v $(SiteScripts)' || true

deploy/static-assets.tar: styles fonts icons images scripts
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - tar the "static-assets" volume into deploy directory'
	@podman run --interactive --rm --mount $(MountAssets)  \
		--entrypoint "tar" $(ALPINE) -czf - /opt/proxy/html 2>/dev/null > $@
