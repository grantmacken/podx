xquery version "3.1";
module namespace res  = "http://xq/#req_res";

declare
function res:status() as element() {
  <rest:response>
    <http:response status="200">
      <http:header name="content-type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer ) as element() {
  <rest:response>
    <http:response status="{string( $status )}">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer, $contentType as xs:string ) as element() {
  <rest:response>
    <http:response status="{string( $status )}">
      <http:header name="Content-Type" value="{$contentType}"/>
    </http:response>
  </rest:response>
};

declare
function res:status( $status as xs:integer, $message as xs:string, $contentType as xs:string ) as element() {
  <rest:response>
    <http:response status="{$status => string()}" message="{$message}">
      <http:header name="Content-Type" value="{$contentType}"/>
    </http:response>
  </rest:response>
};

declare
function res:htmlErr( $map as map(*) ) as element() {
 if ( $map?value instance of map(*) ) 
  then ( res:status( xs:integer( $map?value?status ), 
                      $map?description, 
                      'text/html'))
  else ( res:status( 500, 
                    'internal server error', 
                    'text/html') )
};
