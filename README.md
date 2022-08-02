# podx

A bundle of container images: 
 
1. reverse proxy built for a containerized xqerl: 
2. dockerized web development preprocessing tool chain.

Both reverse proxy and xqerl containers run in a podman pod,
I named the pod 'podx' hence the name of this repo,
The built images built on this repo are all prefixed podx.

## a dockerized web development preprocessing tool chain

All images using start from latest alpine

### podx-alpine
 
 - Directories: additional paths

### podx-w3m

 - From: podx-alpine
 - Entrypoint: 'w3m' exec

terminal browser mainly used to dump browser text

### podx-curl

 - From: podx-alpine
 - Entrypoint: 'curl' exec

### podx-cmark

 - From podx-alpine
 - Used to: convert commonmark (markdown ) into commonmark XML
 - Entrypoint: `cmark --to xml`

XQuery typeswitch expression can be used to transform into HTML

### podx-openresty

 - From: openresty/openresty:alpine-apk
 - Used as: reverse proxy for xqerl
 - Entrypoint: `openresty -p /opt/proxy/ -c /opt/proxy/conf/proxy.conf -g "daemon off;"`
 - Proxy configuration: copied from ./src/proxy
 - Directories:
   -  `/etc/letsencypt` dir created for letsencypt files
   - `/opt/proxy/*` dirs created for nginx files
   - `/usr/local/xqerl/priv/static/assets`  xqerl static assets







<!--

In the podx pod we run 2 containers to serve our web sites.
 1. A nginx server setup as a reverse proxy and cache server. 
 2. A xqerl container which is only reachable on port 8081

[podx-openresty](https://github.com/grantmacken/podx/pkgs/container/podx-openresty)

 This is a alpine os contaner with ngnix server setup as reverse proxy and cache server for xqerl

 [xqerl](https://github.com/grantmacken/xqerl/pkgs/container/xqerl)

The xqerl image is built from my clone of the xqerl repo.

## TODO! examples
1. run via docker-compose file
2. run via podman pod

## TODO! podx docker images - front end helpers

-->


