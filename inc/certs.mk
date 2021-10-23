##############
# self signed certs for example.com
##############

certs: certs-volume certs-conf
certs-volume: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem
certs-conf:  src/proxy/conf/self_signed.conf
certs-pem: src/proxy/certs/example.com.pem # or must be running

certs-volume-check: 
		@podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
			'ls ../certs'

deploy/certs-volume.tar: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
		@podman run --rm  --interactive  --mount $(MountCerts) --entrypoint '["sh", "-c"]'  $(ALPINE) \
			'tar -czf - /opt/proxy/certs' 2>/dev/null > $@

.PHONY: certs-clean
certs-clean: 
	@rm -fv deploy/certs-volume.tar
	@rm -fv src/proxy/certs/* src/proxy/conf/self_signed.conf
	@podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) 'rm -fRv /opt/proxy/certs/*'
	@podman run --rm  --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) 'rm -fv /opt/proxy/conf/self_signed.conf'
	@podman run --rm --workdir /opt/proxy $(ALPINE) ls certs
	@podman run --rm --workdir /opt/proxy $(ALPINE) ls conf

src/proxy/certs/example.com.key:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	 @openssl genrsa -out $@ 2048
	@cat $@ | \
		podman run --rm --interactive --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $@)'
	@podman run --rm  --mount $(MountCerts) $(ALPINE) ls -al /opt/proxy/certs

src/proxy/certs/example.com.csr: src/proxy/certs/example.com.key
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl req -new -key $<  \
		-nodes \
		-subj '/C=NZ/CN=example.com' \
		-out $@ -sha512

src/proxy/certs/example.com.crt: src/proxy/certs/example.com.csr
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl x509 -req -days 365 -in $< -signkey src/proxy/certs/example.com.key -out $@ -sha512
	@cat $@ | \
		podman run --rm --interactive  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $@)'
	@podman run --rm  --mount $(MountCerts) $(ALPINE) ls -al /opt/proxy/certs

src/proxy/conf/self_signed.conf:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@echo "ssl_certificate /opt/proxy/certs/example.com.crt;" > $@
	@echo "ssl_certificate_key /opt/proxy/certs/example.com.key;" >> $@
	@echo "ssl_dhparam /opt/proxy/certs/dhparam.pem;" >> $@
	@cat $@ | \
		podman run --rm  --interactive --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/conf/$(notdir $@)'
	@podman run --rm  --mount $(MountProxyConf) $(ALPINE) ls -al /opt/proxy/conf

src/proxy/certs/dhparam.pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl dhparam -out $@ 2048
	@cat $@ | \
		podman run --rm --interactive --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $@)'
	@podman run --rm  --mount $(MountCerts) $(ALPINE) ls -al /opt/proxy/certs

src/proxy/certs/example.com.pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@if podman inspect --format="{{.State.Running}}" or &>/dev/null 
	then
	@openssl s_client -showcerts -connect example.com:8443 </dev/null \
		| sed -n -e '/-.BEGIN/,/-.END/ p' > $@
	@cat $@ | \
		podman run --rm --interactive  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $@)'
	fi

