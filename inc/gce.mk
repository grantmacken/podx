##############
# google compute engine
##############
#Gscp=gcloud compute scp --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID) $1 $(GCE_NAME):/home/core/$(notdir $1)

.PHONY: gce
gce:
	@#echo -n 'prodman version: ' && $(Gcmd) 'podman -v'
	@echo -n 'groups: ' && $(Gcmd) 'groups'
	@#echo -n 'users: ' && $(Gcmd) 'users'
	@echo -n 'whoami: ' && $(Gcmd) 'whoami'
	@#$(Gcmd) 'printenv'
	@#$(Gcmd) 'podman -v'
	@#$(Gcmd) 'podman network ls'
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
	@$(DASH)
	@$(Gcmd) 'hostnamectl'
	@$(DASH)
	@##TODO set timezone via TZ env var on each container
	@$(Gcmd) 'timedatectl status'

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


.PHONY: gce-xq
gce-xq: # --publish 80:80 --publish 443:443
	@echo "##[ $(@) ]##"
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

# TODO! alternate action - tar content dir then db put content
.PHONY: gce-xqerl-database # copy xqdb into running xq container
gce-xqerl-database: build/xqerl-database.tar.txt
.PHONY: gce-xqerl-database-clean
gce-xqerl-database-clean: 
	@rm build/xqerl-database.tar.txt

build/xqerl-database.tar.txt: deploy/xqerl-database.tar
	@echo '## $(<) ##'
	@mkdir -p $(dir $@)
	@if podman ps -a | grep -q $(XQ)
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


.PHONY: gce-keys
gce-keys: # https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide
	@#gcloud compute project-info describe > .tmp/project.yml
	@#gcloud compute project-info add-metadata --metadata-from-file ssh-keys=.tmp/project.txt
