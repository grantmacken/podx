# podx

Aim: Ready to deploy containerized xQuery application server using podman.
 The pod will be deployed on the google cloud [Compute Engine](https://cloud.google.com/compute)
on an [fedora coreos](https://getfedora.org/en/coreos) VM instance 

The pod is named podx hence the name of this repo. 
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


