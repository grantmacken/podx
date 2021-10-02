# reverse proxy setup

We want or reverse proxy to serve on the SSL port 443, so
the first thing we are going to do is create some self signed certs.

Later on we will use 'letsencypt certs' for a real domain, 
but we will start with out selfsigned certs for our example domain 'example.com'.
Note: the 'or' server does not have to be running as we creating files in two mounted volumes.

```
make certs-create-self-signed
```
1. proxy-conf: this volume now contains a nginx configuration file. 
   - self-signed.conf
2. certs: this volume now contains 
  - dhparam.pem
  - example.com.crt
  - example.com.key

`make confs` to load load and test other nginx configuration files from `src/proxy/conf/` into the proxy-conf volume
`make confs-list` to check to see whats in the proxy-conf volume



## running the reverse proxy 'or' container in the podx pod 

```
make or
```





 

