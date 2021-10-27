module namespace _ = 'http://example.com/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare variable $_:container := 'xq';
(: cmark docs found in the domains content dir :)


declare
  %rest:path("/")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:erewhon(){(
  <rest:response>
    <http:response status="200" message="OK">
      <http:header name="Content-Type" value="text/html"/>
    </http:response>
  </rest:response>,
element html {
    attribute lang {'en'},
    element head {
      element title { 'nowhere' }
      },
    element body {
        element h1 { 'news from erewhon' }
        }
     }
 )};

declare
  %rest:path("/{$domain}/content/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:main($domain, $sCollection, $sItem){
let $dbURI  :=  'http:/' || request:path()
let $pubBase := string-join(('https:','',$domain),'/')
let $dbCollection := $dbURI => substring-before( '/' || $sItem)
let $dbItemList := try{$dbCollection => uri-collection()} catch * {$err:description}  
return
(
  <rest:response>
    <http:response status="200" message="OK">
      <http:header name="Content-Type" value="text/html"/>
    </http:response>
  </rest:response>,

element html {
    attribute lang {'en'},
    element head {
      element title { 'example' }
      },
    element body {
        element h1 { 'example page' },
        element p { request:uri()},
        element p { request:address()},
        element p { request:remote-address()},
        element p { request:path()},
        element p { request:method()},
        element p { request:port()},
        element p { request:remote-port()},
        element p { 'host-name ' || request:hostname()},
        element p { 'db uri: ' || $dbURI },
        element p { 'db collection: ' || $dbCollection },
        element p { 'db error: ' || $dbItemList },
        element p { '----' }

        }
     }
 )};
