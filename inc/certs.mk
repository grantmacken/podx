##############
# self signed certs for example.com
##############
.PHONY: certs-self-sign
certs-self-sign: src/proxy/conf/self-signed.conf

.PHONY: certs-clean
certs-clean: 
	@rm -fv src/proxy/certs/* src/proxy/conf/self-signed.conf
	@podman run --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'rm -fv ./certs/*'
	@podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		-c 'rm -fv ./conf/self-signed.conf'

src/proxy/certs/example.com.key:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	 @openssl genrsa -out $@ 2048
	@cat $@ | podman run --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'cat - > /opt/proxy/certs/$(notdir $@)'

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
	@cat $@ | podman run --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/certs/dhparam.pem: src/proxy/certs/example.com.crt
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '##[ $(notdir $@) ]##'
	@openssl dhparam -out $@ 2048
	@cat $@ | podman run --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'cat - > /opt/proxy/certs/$(notdir $@)'

src/proxy/conf/self-signed.conf: src/proxy/certs/dhparam.pem
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo '## $(notdir $@) ##'
	@echo "ssl_certificate /opt/proxy/certs/example.com.crt;" > $@
	@echo "ssl_certificate_key /opt/proxy/certs/example.com.key;" >> $@
	@echo "ssl_dhparam /opt/proxy/certs/dhparam.pem;" >> $@
	@cat $@ | podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		-c 'cat - > ./conf/$(notdir $@)'
		@podman run --interactive --rm  --mount $(MountProxyConf) --entrypoint "sh" $(OPENRESTY) \
		-c 'ls -al ./conf '
		@podman run --interactive --rm  --mount $(MountCerts) --entrypoint "sh" $(OPENRESTY) \
		-c 'ls -al ./certs '
