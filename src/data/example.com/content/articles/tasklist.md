# Tasklist

- [x] images: use buildah to build docker images that will run in the pod
  - **xqerl image**: 
    - {xqerl_home}/bin/scripts directory preloaded conveniance escripts
    - {xqerl_home}/code/src directory preloaded with restXQ library module. 
    NOTE: The restXQ module when compiled listens on port 8081. 
    The openresty reverse proxy service will fail to boot if xqerl server fails to respond on port 8081

  - **reverse proxy image**: based on the nginx openresty bundle.
    - /opt/proxy set up as the nginx prefix directory with the conf, html, certs, logs and cache directories in this directory
    - the /opt/proxy/conf directory is preloaded with my nginx configuration files sourced from src/proxy/conf
    - openresty starts with the `-c` flag that points to `proxy.conf` as the main nginx configuration file 
    - openresty starts with the `-p` flag that points to `/opt/proxy` directory where it looks to find files
    - ports 80 and port 443 are open for requests, all other posts are closed.
    - all requests on port 80 are redirected to port 443
    - TLS termination ends with the openresty reverse proxy 
    - requests for static-asset resources are served by the front end 'or' server
    - requests for dynamic resources are served by the backend web application 'xq' server via the reverse proxy 'or' server
    - resources served by the backend 'xq' server may be cached by the front end 'or' server set up a *cache server*
<!-- 
https://www.nginx.com/blog/nginx-caching-guide/ 
https://serversforhackers.com/c/nginx-caching
https://github.com/thibaultcha/lua-resty-mlcache
https://groups.google.com/g/openresty-en/c/s7RiYRNvxfI
-->

 - **github packages**: use github actions to 
  - create images: 
  - succeed fail checkpoint: reverse proxy works ok when running containers in pod 
  - create [github packages](https://github.com/grantmacken?tab=packages&repo_name=podx)

- [x] run xqerl container names `xq` and the openresty reverse proxy container name `or` in a 
[pod](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods) 
named podx.

- [x] run podx as a systemd service. Start order is important
  - xqerl boots first. 
    - xqerl application started, 
    - xQuery restXQ modules and their dependences are compiled 
  - reverse proxy server boots only after xqerl modules loaded.
  
- [ ] docker volumes
 - pre-created volumes with `podman volume create`
  - xq (xqerl) mounts
    - xqerl-database: target `/usr/local/xqerl/data'
    - xqerl-compiled-code: target `/usr/local/xqerl/code`
  - or (openresty) mounts
    - letsencrypt: target `/etc/letsencrypt` 
    - proxy-conf:  target `/opt/proxy/conf` 
    - lualib:  target `/usr/local/openresty/site/lualib`
  - static-assets: a shared volume 
   - or: target `/opt/proxy/html`
   - xq: target `/usr/local/openresty/code`
   
## proxy-conf development workflow
 - cd into this repo root
 - terminal: `make watch-confs`
 - editor: edit conf files in src/proxy/conf
 - editor: on save triggers `make confs`

`make confs` pseudo code
1. if file exists on proxy-conf volume
    then create backup file of existing file
    otherwise create backup file with no content
2. copy src into the proxy-conf volume
3. test the ngnix configuration
4. if test succeeds then 
     - remove backup file 
     - with podman exec send signal to reload running `or` proxy server
     - mark success by copying src into build directory
5.  otherwise if test fails
       - in the proxy-conf volume, the backup file is restored 
       - the reason for failure will be in the watch terminal

After nginx configuration files are stored in the proxy-conf volume
the volume is tarred an put into the deploy directory

## static-assets volume

The static-assets volume mount point in the 'or' container  is /opt/proxy/html.
The static-assets volume can also be mounted by the 'xq' container.
The static-assets volume mount point in the 'xq' container is /usr/local/xqerl/priv/static/assets.

This volume holds files that *can* be served directly the nginx prefix **html** directory.
It is also the miss fallback place for files not in the cache. TODO!

## asset processing pipeline

Source asset files for the static-assets volume are located in the src/static-assets directory
Before the asset is stored the file can be pipelined thru docker container instances to get a preferred outcome.
For static assets this outcome usually means a file size reduction.

Processing pipeline example which produces a gzipped svg file with a svgz extension
```   
  article.svg =>
  scour =>
  zopfli =>
  article.svgz
```

## db link to asset

With our static files the goal is to outcomes.
1. a ready to serve assets on the static-assets volume. 
2. the static-assets volume is a commons. This is to avoid overloading the static-asset volume with duplicate binary resources
3. a xqerl db **link** is to the static asset file stored on the static-assets volume
4. If an asset is stored the mounted 'xq' static-asset volume 
   then this asset is also available on 'or'  static-asset volume.

   xqerl db link example:
```
 'http://example.com/icons/article' => 'file:///usr/local/xqerl/priv/static/icons/article.svgz'
  'http://markup.nz/icons/article' => 'file:///usr/local/xqerl/priv/static/icons/article.svgz'
```
  Since the static-assets volume is a commons multiple domain may link to the same resource 

Why have db links to static-assets?

 - links are searchable items. 









<!--

The pod will contain two containers.
1. openresty: mainly as a reverse proxy but also
  - static file server for images and other stuff that does not belong in a database
  - hit miss cache server for the reverse proxy
  - SNI TLS termination at reverse proxy with 
    - everything over TLS port redirection
    - routing to application server via domain name after TLS handshake
  - access control via JWT bearer tokens 
  - certs renewal via ACME dir

2. xqerl: an XDM database with an xQuery 3.1 data query engine running on OTP BEAM
 - a cli for creating retrieving updating and deleting XDM items in the database 
 - default restXQ domain based API endpoints 
    - for creating, retrieving, updating and deleting database collections and resources in collections
    - for ?publishing xQuery modules? that query data in the database  
 - micropub publishing API enpoint routed to restXQ endpoints
 - user endpoint for establishing users and user access scopes via JWT tokens 

 -->
