
##########################################
# generic make function calls
# call should result in success or failure
##########################################
Tick  = printf '\033[32m✔ \033[0m %s' $1
Cross = printf "\033[31m✘ \033[0m %s" $1
# CURL_IMAGE :=  curlimages/curl:$(CURL_VER)
#CONNECT_TO := --connect-to xq:80:xq.$(NETWORK):$(XQERL_PORT) 
#CURL := docker run --rm --interactive --network $(NETWORK) $(CURL_IMAGE) $(CONNECT_TO)
##################################################################
## https://everything.curl.dev/usingcurl/verbose/writeout
##################################################################
WriteOut := '\
url [ %{url} ]\n\
response code [ %{http_code} ]\n\
content type  [ %{content_type} ]\n\
SSL verify    [ %{ssl_verify_result} ] should be zero \n\
remote ip     [ %{remote_ip} ]\n\
local ip      [ %{local_ip} ]\n\
speed         [ %{speed_download} ] the average download speed\n\
SIZE     bytes sent \n\
header   [ %{size_header} ] \n\
request  [ %{size_request} ] \n\
download [ %{size_download} ] \n\
TIMER       [ 0.000000 ] start until \n\
namelookup  [ %{time_namelookup} ] DNS resolution  \n\
connect     [ %{time_connect} ] TCP connect \n\
appconnect: [ %{time_appconnect} ] SSL handhake \n\
pretransfer [ %{time_pretransfer} ] before transfer \n\
transfer    [ %{time_starttransfer} ] transfer start \n\
tansfered   [ %{time_total} ] total transfered '

Crl = curl --silent --show-error \
 --cacert src/proxy/certs/example.com.pem \
 --connect-timeout 1 \
 --max-time 2 \
 --write-out $(WriteOut) \
 --dump-header $1.headers \
 --output $(1).html $2

GrepOK =  grep -q '$(1)' $(2) # equals $1,$2
IsOK  = if $(call GrepOK,$1,$2) ; \
 then $(call Tick, '- [ $(basename $(notdir $2)) ] $3 ');echo;true; \
 else $(call Cross,'- [ $(basename $(notdir $2)) ] $3 ');echo;false;fi
# equals $1,$2 message $3
# fHeader = $(patsubst %/$(1),%/headers-$(1),$(2)) # 1=file 2=headerKey
HasHeaderKey  = grep -q '^$(2)' $(1) # 1=file 2=key 3=value
HasKeyValue   = grep -oP '^$2: \K(.+)$$' $1 | grep -q '^$3'
HeaderKeyValue =  echo "$$( grep -oP '^$2: \K(.+)$$' $1 )"
IsLessThan = if [[ $1 -le $2 ]] ; \
 then $(call Tick, '- [ $1 ] should be less than  [ $2 ] ');echo $3;true; \
 else $(call Cross,'- [ $1 ] should NOT be less than [ $2 ] ');echo $3;false;fi
ServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Tick, '- header [ $2 ] ');echo $3;true; \
 else $(call Cross,'- header [ $2 ] ');echo $3;false;fi
NotServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Cross, '- not ok [ $2 ] should NOT be served');echo;false; \
 else $(call Tick,'- OK! the header [ $2 ] is not being served');echo;true;fi
HasHeaderKeyShowValue = \
 if $(call HasHeaderKey,$1,$2);then $(call Tick, "- header $2: " );$(call HeaderKeyValue,$1,$2);\
 else $(call Cross, "- header $2: " );false;fi
ServesContentType = if $(call HasHeaderKey,$(1),$(2)); then \
 if $(call HasKeyValue,$1,$2,$3); \
 then $(call Tick, '- header [ $2 ] should have value [ $3 ] ');echo ;true; \
 else $(call Cross,'- header [ $2 ] should value [ $3 ] ');echo;false;fi\
 else $(call Cross,'- header [ $2 ] should have value [ $3 ] ');echo;false;fi

PHONY: checks-clean
checks-clean:
	@rm -vfR checks

.PHONY: checks
checks: check-homepage
check-homepage: checks/example.com/home/index
check-remote: checks/remote/example.com/home/index
check-xqerl: checks/code/example.com

checks/code/example.com: build/code/routes.xqm.txt
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@podman run --rm --pod $(POD) $(W3M) -dump_head http://localhost:8081 | tee $@
	@podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081 | tee -a $@
	@grep -q 'server: Cowboy' $@
	@grep -q 'news from erewhon' $@
	@podman run --rm --pod $(POD) $(W3M) -dump http://localhost:8081/example.com/content/home/index | tee -a $@
	@$(DASH)

checks/example.com/home/index: build/code/routes.xqm.txt
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@#$(call Crl,$@,https://example.com:8443/home/index)
	@$(call Crl,$@,https://example.com:8443/) > $@
	@$(call ServesHeader,$@.headers,HTTP/2 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$@.headers,content-type) 
	@$(call HasHeaderKeyShowValue,$@.headers,server)

checks/remote/example.com/home/index: build/code/example.com.xqm.txt
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@$(Gcmd) 'sudo podman run --rm --pod $(POD) --mount $(MountCerts) $(CURL) \
		--cacert /opt/proxy/certs/example.com.pem \
		--verbose \
		--show-error \
	  --connect-timeout 1 \
	  --max-time 2 \
		https://example.com:'

checks/$(DOMAIN)/styles/index:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@curl --silent --show-error \
 --cacert src/proxy/certs/example.com.pem \
 --write-out $(WriteOut) \
 --connect-timeout 1 \
 --max-time 2 \
 --dump-header $(dir $@)/$(notdir $@).headers \
 --output $(dir $@)/$(notdir $@).css \
 https://$(DOMAIN):8443/styles/index > $@
	@$(DASH)
	@grep url $@
	@$(DASH)
	@#$(DASH)
	@#cat $@
	@#echo && $(DASH)
	@#cat $@.css
	@#echo && $(DASH)
	@#cat $@.headers
	@#$(DASH)
	@$(call ServesHeader,$@.headers,HTTP/2 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$@.headers,content-type) 
	@$(call HasHeaderKeyShowValue,$@.headers,server)
	@$(call HasHeaderKeyShowValue,$@.headers,date)
	@$(call HasHeaderKeyShowValue,$@.headers,vary)
	@$(DASH)

checks/$(DOMAIN)/scripts/prism:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@curl --silent --show-error \
 --cacert src/proxy/certs/example.com.pem \
 --write-out $(WriteOut) \
 --connect-timeout 1 \
 --max-time 2 \
 --dump-header $(dir $@)/$(notdir $@).headers \
 --output $(dir $@)/$(notdir $@).js \
 https://$(DOMAIN):8443/scripts/prism > $@
	@#$(DASH)
	@#cat $@
	@#echo && $(DASH)
	@#cat $@.js
	@#echo && $(DASH)
	@#cat $@.headers
	@#$(DASH)
	@$(DASH)
	@grep url $@
	@$(DASH)
	@$(call ServesHeader,$@.headers,HTTP/2 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$@.headers,content-type) 
	@$(call HasHeaderKeyShowValue,$@.headers,server)
	@$(call HasHeaderKeyShowValue,$@.headers,date)
	@$(DASH)
