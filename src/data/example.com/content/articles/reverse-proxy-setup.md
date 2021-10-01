# reverse proxy setup

We want or reverse proxy to serve on the SSL port 443, so
the first thing we are going to do is create some self signed certs.

Later on we will use 'letsencypt certs' for a real domain, 
but we will start with out selfsigned certs for our example domain 'example.com'.

```
make certs-create-self-signed
```



 


