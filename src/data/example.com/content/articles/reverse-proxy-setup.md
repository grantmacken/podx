# openresty reverse proxy setup for restxq 

`make certs-create-self-signed` create some self signed certs. 

Later on we will use 'letsencypt certs' for a real domain, 
but we will start with out self-signed certs for our example domain 'example.com'.
After invoking command: 

1. proxy-conf: this volume now contains a nginx configuration file. 
   - self-signed.conf
2. certs: this volume now contains 
  - dhparam.pem
  - example.com.crt
  - example.com.key

`make confs`: to load load and test other nginx configuration files from `src/proxy/conf/` into the proxy-conf volume

`make confs-list`: to check to see whats in the proxy-conf volume

`make or`: to run the reverse proxy 'or' container in the podx pod 

