# podx

Aim: Ready to deploy containerized xQuery application server using podman.
 The pod will be deployed on the google cloud [Compute Engine](https://cloud.google.com/compute)
on an [fedora coreos](https://getfedora.org/en/coreos) VM instance 

The pod is named podx hence the name of this repo. 
In the podx pod we run 2 containers to serve our web sites.
 1. A nginx server setup as a reverse proxy and cache server. 
 2. A xqerl container which is only reachable on port 8081


