 [xqerl](https://zadean.github.io/xqerl)
 maintained by 
 [Zachary Dean](https://github.com/zadean),
 is an Erlang XQuery 3.1 Processor and XML Database.

xQuery 3.1 Processor:
* a well tested xQuery 3.1 Processor
* built for xQuery 3.1, with no prior baggage making it more lean.
* built with erlang, compiled to run as a **reliable** OTP beam application


```nginx
location ~* /styles/.+ {
  rewrite "^/(styles)/(\w+)([?\.]{1}\w+)?$" /static-assets/$1/$2.css break;
  default_type "text/css; charset=utf-8";
  add_header Vary Accept-Encoding;
  gzip off;
  gzip_static  always;
  gunzip on;
  root html/$domain;
}
