BASE_URL := https://$(DOMAIN):8443
PEM := .tmp/$(DOMAIN).pem

##########################################
# generic make function calls
# call should result in success or failure
##########################################
Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1
# CURL_IMAGE :=  curlimages/curl:$(CURL_VER)
#CONNECT_TO := --connect-to xq:80:xq.$(NETWORK):$(XQERL_PORT) 
#CURL := docker run --rm --interactive --network $(NETWORK) $(CURL_IMAGE) $(CONNECT_TO)
##################################################################
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout
##################################################################
WriteOut := '\
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
 GET = curl --silent --show-error \
 --cacert $(PEM) \
 --write-out $(WriteOut) \
 --connect-timeout 1 \
 --max-time 2 \
 --resolve $(DOMAIN):8443:127.0.0.1 \
 --dump-header $(dir $2)/$(notdir $2).headers \
 --output $(dir $2)/$(notdir $2).html \
 https://$(DOMAIN):8443$1 > $2

.PHONY: check-init
check-init: $(PEM)

.tmp/$(DOMAIN).pem:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@openssl s_client -showcerts -connect $(DOMAIN):8443 </dev/null \
		| sed -n -e '/-.BEGIN/,/-.END/ p' > $@

.PHONY: check-clean
check-clean:
	@rm -fr checks

.PHONY: check
check: check-init checks/$(DOMAIN)/home/index

checks/$(DOMAIN)/home/index:
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@$(call GET,'/',$@)
	@$(DASH)
	@cat $@
	@echo && $(DASH)
	@cat $@.html
	@echo && $(DASH)
	@cat $@.headers
	@$(DASH)
	@$(call ServesHeader,$@.headers,HTTP/2 200, - status OK!)
	@$(call HasHeaderKeyShowValue,$@.headers,content-type)
	@$(call HasHeaderKeyShowValue,$@.headers,server)
	@$(call HasHeaderKeyShowValue,$@.headers,date)
	@$(DASH)

# fHeader = $(patsubst %/$(1),%/headers-$(1),$(2)) # 1=file 2=headerKey


