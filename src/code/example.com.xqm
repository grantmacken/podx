module namespace _ = 'http://example.com/#routes';
import module namespace  cm  = "http://xq/#cmarkup";

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
  %rest:path("/example.com/content/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:collection-item( $sCollection, $sItem ){
 try {
  let $sType := 'entry'
  let $pubURL       := string-join(($_:pubBase,$sCollection,$sItem),'/' )
  let $dbCollection := string-join(($_:dbBase,$sCollection),'/' )
  let $dbItemList := $dbCollection => uri-collection()
  let $resMap := map { 
  "domain": $_:domain,
  "collection": $sCollection,
  "item": $sItem,
  'db-collection': $dbCollection,
  'uri' : $pubURL,
  'base-uri' : $_:pubBase
  }
  let $dbCmark       := string-join(($_:dbBase,$sCollection,$sItem || '.cmark'),'/' )
  let $hasCmark := $dbCmark = ($dbItemList)
  let $contentMap := if( $hasCmark ) then ( 
    (: create map with map constructor :)
     map{ 'content':   $dbCmark => db:get() => cm:dispatch() }
  ) else ( map {} )

  (: the site data map - site wide data :)
  let $dbSiteData := string-join(($_:dbBase,'site.map'),'/' )
  let $siteMap :=  try{$dbSiteData => db:get()} catch * { map {} }

 (: the collection data map - data for all items in collection :)
  let $dbCollectionData := string-join(($_:dbBase,$sCollection,'default.map'),'/' )
  let $hasCollectionData := $dbCollectionData = ($dbItemList)
  let $collectionMap := if( $hasCollectionData ) then ( $dbCollectionData => db:get() ) else ( map {} )

 (: the page data map - data for a single page:)
  let $dbPageData := string-join(($_:dbBase,$sCollection,$sItem || '.map'),'/' )
  let $hasPageData := $dbPageData = ($dbItemList)
  let $pageMap := if( $hasPageData ) then ( $dbPageData => db:get() ) else ( map {} )

  let $dbCollectionTemplate := string-join(($_:dbBase,$sCollection, 'default.tpl'),'/' )
  let $dbCollectionIndexTemplate := string-join(($_:dbBase,$sCollection, 'default.tpl'),'/' )
  let $tplFunction := 
  if ( string-join(($_:dbBase,$sCollection, $sItem,'.tpl'),'/' ) = ($dbItemList)) 
  then (  (: there is a template named after the item e.g, index.tpl :)
   string-join(($_:dbBase,$sCollection, $sItem,'.tpl'),'/' ) => db:get()
   ) 
  else ( 
    if ( string-join(($_:dbBase,$sCollection, 'default.tpl'),'/' ) = ($dbItemList)) 
    then (  (: get the collections default template :)
     string-join(($_:dbBase,$sCollection, 'default.tpl'),'/' ) => db:get()
     )
    else ( string-join(($_:dbBase, 'default.tpl'),'/' ) => db:get())
  )
 
  (: TODO  merge maps :)
  return(
  _:status( 200, 'OK', 'text/html'),
  map:merge(( $resMap, $siteMap, $collectionMap, $pageMap, $contentMap ))  => $tplFunction() 
)} catch * {(
  map { 'code' : $err:code,
        'description' : $err:description,
        'value' : $err:value
      } => _:htmlErr(),
element html {
    attribute lang {'en'},
    element head {
      element title { 'Error!' }
      },
    element body {
        element h1 { 'We have a problem' },
        element dl {
          element dt { 'error code' },
          element dd { $err:code },
          element dt { 'error description' },
          element dd {  $err:description },
          element dt { 'error value' },
          element dd {  $err:value }
          }
        }
     }
  )}
};

declare
function _:htmlErr( $map as map(*) ) as element() {
 if ( $map?value instance of map(*) ) 
  then ( _:status( xs:integer( $map?value?status ), 
                      $map?description, 
                      'text/html'))
  else ( _:status( 500, 
                    'internal server error', 
                    'text/html') )
};

declare
function _:status( $status as xs:integer, $message as xs:string, $contentType as xs:string ) as element() {
  <rest:response>
    <http:response status="{$status => string()}" message="{$message}">
      <http:header name="Content-Type" value="{$contentType}"/>
    </http:response>
  </rest:response>
};

