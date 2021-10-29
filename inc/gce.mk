##############
# google compute engine
##############
#Gscp=gcloud compute scp --zone=$(GCE_ZONE) --project $(GCE_PROJECT_ID) $1 $(GCE_NAME):/home/core/$(notdir $1)
# NOTES:
# only /var and /etc are writable 

#GceIPAddress := $(shell $(Gcmd) 'sudo podman inspect or' | jq -r '.[].NetworkSettings.Networks.podman.IPAddress')
#GceGateway := $(shell $(Gcmd) 'sudo podman inspect or' |   jq -r '.[].NetworkSettings.Networks.podman.Gateway')

.PHONY: gce-network
gce-network: .gce.env
	@#grep -q GCE_IPADDRESS=$(GceIPAddress) $< || echo 'GCE_IPADDRESS=$(GceIPAddress)' >> $<
	@#grep -q GCE_GATEWAY=$(GceGateway)     $< || echo 'GCE_GATEWAY=$(GceGateway)'     >> $<
	@#$(Gcmd) 'cat /etc/hosts' # 10.152.0.8   example.com
	@#$(Gcmd) 'sudo podman network ls'
	@#$(Gcmd) 'sudo podman run --pod $(POD) --rm $(CURL) http://example.com/ --resolve example.com:80:$(GCE_IPADDRESS)'
	@#$(Gcmd) 'sudo podman run --rm $(CURL) $(GCE_IPADDRESS):8081'
	@#$(Gcmd) 'sudo podman run --rm $(CURL) $(GCE_IPADDRESS):8081'
	@$(Gcmd) 'cat /etc/cni/net.d/87-podman.conflist' 

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

.PHONY: gce-or-info
gce-or-info:
	@$(Gcmd) 'sudo podman pod list'
	@$(Gcmd) "sudo podman ps -a --pod"
	@$(DASH)
	@$(Gcmd) 'sudo podman top or' || true
	@$(DASH)
	@podman inspect or' | jq '.[].NetworkSettings.Networks.podman.IPAddress
	@$(Gcmd) 'sudo podman inspect or' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@$(Gcmd) 'sudo podman inspect xq' | jq '.[].NetworkSettings.Networks.podman.IPAddress'
	@#$(Gcmd) 'sudo podman pod list'
	@$(DASH)

