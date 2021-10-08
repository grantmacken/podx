##############
# self signed certs for example.com
##############

certs-volume: deploy/certs-volume.tar
certs-conf:  src/proxy/conf/self_signed.conf
cacert: src/proxy/certs/$(DOMAIN).pem # or must be running

certs-volume-check: 
		@podman run --rm  --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
			'ls ../certs'

deploy/certs-volume.tar: src/proxy/certs/example.com.crt src/proxy/certs/dhparam.pem
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

src/proxy/certs/dhparam.pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl dhparam -out $@ 2048
	@cat $@ | \
		podman run --rm --interactive --mount $(MountCerts) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/conf/self_signed.conf:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@echo "ssl_certificate /opt/proxy/certs/example.com.crt;" > $@
	@echo "ssl_certificate_key /opt/proxy/certs/example.com.key;" >> $@
	@echo "ssl_dhparam /opt/proxy/certs/dhparam.pem;" >> $@
	@cat $@ | \
		podman run --rm  --interactive --mount $(MountProxyConf) --entrypoint '["sh", "-c"]' $(ALPINE) \
		'cat - > /opt/proxy/conf/$(notdir $@)'

src/proxy/certs/$(DOMAIN).pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@openssl s_client -showcerts -connect $(DOMAIN):8443 </dev/null \
		| sed -n -e '/-.BEGIN/,/-.END/ p' > $@

