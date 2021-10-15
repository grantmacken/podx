##############
# google compute engine
##############
GCE_PROJECT_ID := gmack-200121
GCE_ZONE := australia-southeast1-b
GCE_NAME := core@podx
TLS_COMMON_NAME := gmack.nz
DOMAINS := gmack.nz,markup.nz
Gssh := gcloud compute ssh $(GCE_NAME) --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID)
Gcmd := $(Gssh) --command
#Gscp=gcloud compute scp --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID) $1 $(GCE_NAME):/home/core/$(notdir $1)

.PHONY: gce
gce:
	@#echo -n 'prodman version: ' && $(Gcmd) 'podman -v'
	@#echo -n 'groups: ' && $(Gcmd) 'groups'
	@#echo -n 'users: ' && $(Gcmd) 'users'
	@#echo -n 'whoami: ' && $(Gcmd) 'whoami'
	@#$(Gcmd) 'printenv'
	@#$(Gcmd) 'podman -v'
	@$(Gcmd) 'podman network ls'
	@#$(Gcmd) 'sudo podman image list'
	@#$(Gcmd) 'sudo ls -al /home/core' || true
	@#gcloud compute project-info describe > .tmp/project.yml
	@$(DASH)
	@$(Gcmd) 'sudo podman ps --all --pod' || true
	@$(DASH)
	@$(Gcmd) 'sudo podman top xq' || true
	@$(DASH)
	@$(Gcmd) 'sudo podman stats --all --no-stream' || true
	@$(DASH)
	@$(Gcmd) 'sudo podman stats --no-stream --format "table {{.ID}} {{.Name}} {{.MemUsage}}" xq'
	@$(DASH)
	@#$(Gcmd) 'sudo podman run --pod $(POD) --rm $(W3M) -dump_extra http://localhost:8081/example.com/home/index'

.PHONY: gce-view
gce-view:
	@#$(Gcmd) 'sudo podman inspect xq' | jq '.[].Config.Env'
	@#$(Gcmd) 'sudo podman inspect xq' | jq '.[].NetworkSettings.Networks.podman.Gateway'
	@#$(Gcmd) 'sudo podman inspect xq' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@# $(Gcmd) 'sudo podman inspect xq' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@#$(Gcmd) 'sudo podman run --pod $(POD) --net podman --rm $(W3M) -dump_source http://10.88.0.44:8081/example.com/content/home/index'
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountCerts) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(CURL) 'ls /opt/proxy/certs'"

PHONEY: gce-clean
gce-clean: 
	@$(Gcmd) 'podman pod stop -a' || true
	@$(Gcmd) 'podman pod rm $(POD)' || true
	@$(Gcmd) 'podman ps --all --pod' || true

PHONEY: gce-volumes-rm
gce-volumes-rm: 
	@$(Gcmd) 'podman volume exists static-assets && podman volume rm static-assets' || true
	@$(Gcmd) 'podman volume exists proxy-conf && podman volume rm proxy-conf' || true
	@$(Gcmd) 'podman volume exists certs && podman volume rm certs' || true
	@$(Gcmd) 'podman volume exists lualib && podman volume rm lualib' || true
	@$(Gcmd) 'podman volume exists xqerl-database && podman volume rm xqerl-database' || true
	@$(Gcmd) 'podman volume exists xqerl-compiled-code && podman volume rm xqerl-compiled-code' || true
	@$(Gcmd) 'podman volume ls' || true

PHONEY: gce-volumes
gce-volumes: 
	@$(Gcmd) 'sudo podman volume exists static-assets || podman volume create static-assets'
	@$(Gcmd) 'sudo podman volume exists proxy-conf || podman volume create proxy-conf'
	@$(Gcmd) 'sudo podman volume exists certs || podman volume create certs'
	@$(Gcmd) 'sudo podman volume exists lualib || podman volume create lualib'
	@$(Gcmd) 'sudo podman volume exists xqerl-database || podman volume create xqerl-database'
	@$(Gcmd) 'sudo podman volume exists xqerl-compiled-code || podman volume create xqerl-compiled-code'
	@$(Gcmd) 'sudo podman volume ls'

.PHONY: gce-pull
gce-pull: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman pull $(ALPINE)'
	@$(Gcmd) 'sudo podman pull $(OR)'
	@$(Gcmd) 'sudo podman pull $(XQ)'
	@$(Gcmd) 'sudo podman pull $(CURL)'
	@$(Gcmd) 'sudo podman image list'

.PHONY: gce-images-rm
gce-images-rm:
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman rmi $(ALPINE)'
	@$(Gcmd) 'sudo podman rmi $(OR)'
	@$(Gcmd) 'sudo podman rmi $(XQ)'
	@$(Gcmd) 'sudo podman image list'

.PHONY: gce-podx
gce-podx: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) 'sudo podman pod create -p 80:80 -p 443:443 --name $(POD)'
	@$(Gcmd) 'sudo podman run --pod $(POD) --mount $(MountCode) --mount $(MountData) --network podman --name xq --detach $(XQ)'

.PHONY: gce-xq
gce-xq: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) "sudo podman exec xq xqerl eval 'application:ensure_all_started(xqerl).'"
	@$(Gcmd) "sudo podman exec xq ls ./code"

.PHONY: gce-or
gce-or: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
	@$(Gcmd) "sudo podman run --pod $(POD) \
		    --mount $(MountCerts) --mount $(MountProxyConf) --mount $(MountAssets) \
		--name or \
    --detach $(OR)"
	@$(Gcmd) "sudo podman ps -a --pod"
	@$(Gcmd) 'sudo podman top or' || true


.PHONY: gce-or-info
gce-or-info:
	@$(Gcmd) 'sudo podman pod list'
	@$(Gcmd) "sudo podman ps -a --pod"
	@$(DASH)
	@$(Gcmd) 'sudo podman top or' || true
	@$(DASH)
	@$(Gcmd) 'sudo podman inspect or' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@$(Gcmd) 'sudo podman inspect xq' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@$(Gcmd) 'sudo podman pod list'
	@$(DASH)


.PHONY: gce-or-view
gce-or-view:
	@IP=$(shell $(Gcmd) 'sudo podman inspect or' | jq '.[].NetworkSettings.Networks.podman.IPAddress' )
	@echo $$IP
	@#$(Gcmd) 'sudo podman run --pod $(POD) --rm  $(CURL) --version'
	@$(Gcmd) 'sudo podman run --pod $(POD) --rm  $(CURL) http://example.com --resolve example.com:80:127.0.0.1'

PHONEY: gce-instance-create
gce-instance-create: 
		@#gcloud compute images describe-from-family --project "fedora-coreos-cloud" "fedora-coreos-${STREAM}"
		@#gcloud compute instances create --image-project "fedora-coreos-cloud" --image-family "fedora-coreos-${STREAM}" "${VM_NAME}"
		@#cloud compute instances list
		@#gcloud compute project-info describe

.PHONY: gce-xqerl-code
gce-xqerl-code: build/xqerl-code-source.tar.txt
	@echo '## $(@) ##'
	@if $(Gcmd) 'sudo podman inspect --format="{{.State.Running}}" xq &>/dev/null' 
	then
	@$(Gcmd) 'sudo podman exec xq ls code/src'
	@#$(Gcmd) 'sudo podman exec xq xqerl eval "{ok, CurrentDirectory} = file:get_cwd()."'
	@$(Gcmd) 'sudo podman exec xq xqerl eval "xqerl:compile(\"code/src/cmarkup.xqm\")."'
	@$(Gcmd) 'sudo podman exec xq xqerl eval "xqerl:compile(\"code/src/example.com.xqm\")."'
	fi

build/xqerl-code-source.tar.txt: deploy/xqerl-code-source.tar
	@echo '## $(<) ##'
	@mkdir -p $(dir $@)
	@echo ' - copying $(notdir $<) tar onto GCE host'
	@gcloud compute scp $< $(GCE_NAME):/home/core/$(notdir $<)
	@echo ' - copying tar onto code-volume'
	@$(Gcmd) "cat /var/home/core/$(notdir $<) | \
		 sudo podman run --rm --interactive \
    --mount  $(MountCode) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'cat - > /usr/local/xqerl/code/src/$(notdir $<)'" 
	@echo ' - untar tar onto code-volume'
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountCode) \
		--entrypoint '[\"tar\"]' $(ALPINE) xvf /usr/local/xqerl/code/src/$(notdir $<) -C / "
	@#echo ' - list code-volume source files'
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountCode) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'rm /usr/local/xqerl/code/src/$(notdir $<) && ls -l /usr/local/xqerl/code/src'" > $@

# TODO! alternate action - tar content dir then db put content
.PHONY: gce-xqerl-database # copy xqdb into running xq container
gce-xqerl-database: build/xqerl-database.tar.txt
.PHONY: gce-xqerl-database-clean
gce-xqerl-database-clean: 
	@rm build/xqerl-database.tar.txt

build/xqerl-database.tar.txt: deploy/xqerl-database.tar
	@echo '## $(<) ##'
	@mkdir -p $(dir $@)
	@if $(Gcmd) 'sudo podman inspect --format="{{.State.Running}}" xq &>/dev/null' 
	then
	@echo ' - copying $(notdir $<) tar onto GCE host'
	@gcloud compute scp $< $(GCE_NAME):/home/core/$(notdir $<)
	@echo -n ' - stopping container: '
	@$(Gcmd) 'sudo podman stop xq' || true
	@echo ' - copying tar into volume'
	@$(Gcmd) "cat /var/home/core/$(notdir $<) | \
		 sudo podman run --rm --interactive \
    --mount  $(MountData) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'cat - > /usr/local/xqerl/data/$(notdir $<)'" 
	@echo ' - untar tar into volume'
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountData) \
		--entrypoint '[\"tar\"]' $(ALPINE) xvf /usr/local/xqerl/data/$(notdir $<) -C / " | tee @
	@echo -n ' - starting container: '
	@$(Gcmd) "sudo podman start xq" || true
	@echo -n ' - remove tar artifact: '
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountData) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'rm -v /usr/local/xqerl/data/$(notdir $<)'" 
	@$(Gcmd) 'sudo podman start xq' || true
	fi

.PHONY: gce-proxy-conf  # place nginx configuration into proxy-conf volume
gce-proxy-conf: build/proxy-conf.tar.txt

.PHONY: gce-proxy-conf-clean
gce-proxy-conf-clean: 
	@rm build/proxy-conf.tar.txt

build/proxy-conf.tar.txt: deploy/proxy-conf.tar
	@echo '##[ $(<) ]##'
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - upload tar into GCE host: '
	@gcloud compute scp $< $(GCE_NAME):/home/core/$(notdir $<)
	@echo ' - move tar into container: '
	@$(Gcmd) "cat /home/core/$(notdir $<) | \
		 sudo podman run --rm --interactive \
    --mount  $(MountProxyConf) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'cat - > /opt/proxy/conf/$(notdir $<)'" 
	@echo ' - untar tar into volume'
	@$(DASH)
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountProxyConf) \
		--entrypoint '[\"tar\"]' $(ALPINE) xvf /opt/proxy/conf/$(notdir $<) -C / " | tee $@
	@$(DASH)
	@echo -n ' - remove tar artifact: '
	@$(Gcmd) "rm -v /home/core/$(notdir $<)"

.PHONY: gce-static-assets  # place static assets into static assets-volume
gce-static-assets: build/static-assets.tar.txt

.PHONY: gce-static-assets-clean
gce-static-assets-clean: 
	@rm build/static-assets.tar.txt

build/static-assets.tar.txt: deploy/static-assets.tar
	@echo '##[ $(<) ]##'
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - upload tar into GCE host: '
	@gcloud compute scp $< $(GCE_NAME):/home/core/$(notdir $<)
	@echo ' - move tar into container: '
	@$(Gcmd) "cat /home/core/$(notdir $<) | \
		 sudo podman run --rm --interactive \
    --mount  $(MountAssets) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'cat - > /opt/proxy/html/$(notdir $<)'" 
	@echo ' - untar tar into volume'
	@$(DASH)
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountAssets) \
		--entrypoint '[\"tar\"]' $(ALPINE) xvf /opt/proxy/html/$(notdir $<) -C / " | tee $@
	@$(DASH)
	@echo -n ' - remove tar artifact: '
	@$(Gcmd) "rm -v /home/core/$(notdir $<)"

.PHONY: gce-certs  # place static assets into static assets-volume
gce-certs: build/certs.tar.txt

.PHONY: gce-certs-clean
gce-certs-clean: 
	@rm build/certs.tar.txt

build/certs.tar.txt: deploy/certs.tar
	@echo '##[ $(<) ]##'
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo ' - upload tar into GCE host: '
	@gcloud compute scp $< $(GCE_NAME):/home/core/$(notdir $<)
	@echo ' - move tar into container: '
	@$(Gcmd) "cat /home/core/$(notdir $<) | \
		 sudo podman run --rm --interactive \
    --mount  $(MountCerts) \
		--entrypoint '[\"/bin/sh\", \"-c\"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $<)'" 
	@echo ' - untar tar into volume'
	@$(DASH)
	@$(Gcmd) "sudo podman run --rm  \
    --mount  $(MountCerts) \
		--entrypoint '[\"tar\"]' $(ALPINE) xvf /opt/proxy/certs/$(notdir $<) -C / " | tee $@
	@$(DASH)
	@echo -n ' - remove tar artifact: '
	@$(Gcmd) "rm -v /home/core/$(notdir $<)"

.PHONY: gce-keys
gce-keys: # https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide
	@#gcloud compute project-info describe > .tmp/project.yml
	@#gcloud compute project-info add-metadata --metadata-from-file ssh-keys=.tmp/project.txt
