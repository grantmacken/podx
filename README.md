# podx

WIP: A bundle of docker images: 
 
1. reverse proxy for a containerized xerl: 
2. dockerized web dev preprocessing tool chain.

Both reverse proxy and xqerl containers run in a podman pod,
I named the pod 'podx' hence the name of this repo,
The built images built on this repo are all prefixed podx.

Some stuff in this repo, will be moved out soon.
 
The stuff in this repo will from now on concentrate 
on building helper images for web development projects.



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


