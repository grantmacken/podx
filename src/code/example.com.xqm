module namespace _ = 'http://example.com/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare variable $_:container := 'xq';
declare variable $_:domain := 'example.com';
(: cmark docs found in the domains content dir :)
declare variable $_:dbBase  := string-join(('http:','',$_:domain,'content' ),'/');
declare variable $_:pubBase := string-join(('https:','',$_:domain),'/');

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
  %rest:path("/example.com/content/home/index")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:exampleHomeIndex(){(
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
        element h1 { 'example page' }
        }
     }
 )};
