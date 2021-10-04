######################
###  STATIC ASSETS ###
######################

DomainStylesList := $(wildcard src/static_assets/*/styles/*.css)
CommonStylesList := $(wildcard src/static_assets/styles/*.css)

IconsList := $(wildcard src/static_assets/icons/*.svg)
FontsList := $(wildcard src/static_assets/fonts/*.woff2)

BuildStyles := $(patsubst src/%,build/%.txt,$(DomainStylesList))
BuildFonts := $(patsubst src/%.woff2,build/%.txt,$(FontsList))
BuildIcons := $(patsubst src/%.svg,build/%.svgz.txt,$(IconsList))

.PHONY: assets
assets: deploy/static-assets.tar

.PHONY: styles
styles: $(BuildStyles)

.PHONY: fonts
fonts: $(BuildFonts)

.PHONY: icons
icons: $(BuildIcons)

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
	@echo "##[ $(*).woff2 ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@cat $< | podman run --interactive --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE)  \
		'cat - > $(*).woff2'
	@echo '$(notdir $<)' > $@ 

.PHONY: fonts-list
fonts-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls fonts

#############
### ICONS ###
#############
# these are in the commons

build/static_assets/icons/%.svgz.txt: src/static_assets/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@cat $< | \
    podman run --rm --interactive ${ZOPFLI} | \
		podman run --interactive --rm  --mount $(MountAssets) --entrypoint '["/bin/sh", "-c"]' $(ALPINE)  \
		'cat - > icons/$(*).svgz'

.PHONY: icons-list
icons-list:
	@echo '## $(@) ##'
	@podman run --rm --mount $(MountAssets) $(ALPINE) ls icons


################
###  IMAGES  ###
################
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
### SCRIPTS ###
### TODO webpack
################
build/static_assets/scripts/%.txt: src/static_assets/scripts/%.js
	@echo "##[ $< ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@bin/xq link $(DOMAIN) scripts/$(*).js | tee $@

deploy/static-assets.tar: styles fonts icons
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - tar the "static-assets" volume into deploy directory'
	@podman run --interactive --rm --mount $(MountAssets)  \
		--entrypoint "tar" $(ALPINE) -czf - /opt/proxy/html 2>/dev/null > $@
