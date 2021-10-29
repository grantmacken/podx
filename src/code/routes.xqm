module namespace _ = 'http://example.com/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace err = "http://www.w3.org/2005/xqt-errors";
declare namespace cm ="http://commonmark.org/xml/1.0";
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
  %rest:path("/{$sDomain}/content/{$sCollection}/{$sItem}")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function _:main($sDomain, $sCollection, $sItem){
let $dbURI  :=  'http:/' || request:path()
let $pubBase := string-join(('https:','',$sDomain),'/')
let $dbCollection := $dbURI => substring-before( '/' || $sItem)
let $dbItemList := try{$dbCollection => uri-collection()} catch * {()}  
let $dbCmark    := $dbURI || '.cmark'
let $hasCmark  := $dbCmark = ($dbItemList)
let $docCmark := 
  if ( $hasCmark )
  then try{ $dbCmark => db:get()} catch * {()}
  else ()

let $dbTemplate := $dbCollection || '/default.tpl'
let $hasTemplate  := $dbTemplate = ($dbItemList)
let $tplFunction := 
  if ( $hasTemplate )
  then try{ $dbTemplate => db:get()} catch * {()}
  else ()
let $resMap := map { 
  "domain": $sDomain,
  "collection": $sCollection,
  "item": $sItem
  }
return 
  if ( not( $docCmark instance of document-node() ) )
  then  _:resNoItem($sDomain, $sCollection, $sItem)
  else 
    if ( not($tplFunction instance of function(*)) )
    then _:resNoItem($sDomain, $sCollection, $sItem)
    else 
     let $fmMap :=  try{$docCmark => _:frontmatter()} catch * { map{} }
     let $contentMap :=  try{ map { 'content': $docCmark => _:dispatch()}} catch * { map{} }
     let $res := map:merge(( $fmMap, $resMap, $contentMap)) => $tplFunction()
     return 
      if ( $res instance of element() )
      then _:resOK($res)
      else _:resNoItem($sDomain, $sCollection, $sItem )
};

declare function _:resNoItem($sDomain, $sCollection, $sItem){
(
<rest:response>
  <http:response status="200" message="OK">
    <http:header name="Content-Type" value="text/html"/>
  </http:response>
</rest:response>,
element html {
    attribute lang {'en'},
    element head {
      element title { 'route' }
      },
    element body {
        element h1 { 'No ITEM page' },
        element p { 'uri: ' || request:uri()},
        element p { 'domain: ' || $sDomain },
        element p { 'collection: ' || $sCollection },
        element p { 'item: ' || $sItem },
        element p { '--ERROR --' }
        }
     }
 )
};


declare function _:resOK( $res ){
(
  <rest:response>
    <http:response status="200" message="OK">
      <http:header name="Content-Type" value="text/html"/>
    </http:response>
  </rest:response>,
  $res
 )
};

declare
function _:frontmatter( $body as document-node() ) as map(*) {
 try{ 
  if ( $body/cm:document/cm:html_block[1]/comment() )
  then 
    $body/cm:document/cm:html_block[1]/comment() 
    => string() 
    => parse-json()
  else map {}
  } catch * { map {} }
};

(:~
recursive typeswitch descent for a commonmark XML document
@see https://github.com/commonmark/commonmark-spec/blob/master/CommonMark.dtd

Block Elements
block_quote|list|code_block|paragraph|heading|thematic_break|html_block|custom_bloc

Inline Elements
text|softbreak|linebreak|code|emph|strong|link|image|html_inline|custom_inline

@param  nodes to process
@return result node
:)
declare
function _:dispatch( $nodes as node()* ) as item()* {
 for $node in $nodes
  return
    typeswitch ($node)
    case document-node() return (
        for $child in $node/node()
        return ( _:dispatch( $child) )
        )
     case element( cm:document ) return _:document( $node )
    (: BLOCK :)
    case element( cm:block_quote ) return 'blockquote' => _:block( $node )
    case element( cm:list ) return $node => _:list( )
    case element( cm:item ) return 'li' => _:block( $node )
    case element( cm:code_block ) return  $node => _:codeBlock( )
    case element( cm:paragraph ) return  'p' => _:block( $node )
    case element( cm:heading ) return _:heading( $node )
    case element( cm:thematic_break )  return 'hr' => _:block( $node )
    case element( cm:html_block ) return _:htmlBlock( $node )
    (: INLINE:)
    case element( cm:text ) return $node/text()
    case element( cm:softbreak ) return ( )
    case element( cm:linebreak ) return 'br' => _:inline( $node ) 
    case element( cm:code ) return 'code' => _:inline( $node )
    case element( cm:emph ) return 'em' => _:inline( $node )
    case element( cm:strong ) return 'strong' => _:inline( $node )
    case element( cm:link ) return _:link( $node )
    case element( cm:image ) return $node => _:image( )
    (: case element( cm:html_inline ) return _:passthru( $node ) :)
    (: case element( cm:custom_inline ) return _:passthru( $node ) :)
    case element() return _:passthru( $node )
    default return $node
};

(:~
make a copy of the node to return to dispatch
@param  HTML template node as a node()
@return a copy of the template node
:)
declare
function _:passthru( $node as node()* ) as item()* {
       element { local-name($node) } {
          for $child in $node
          return _:dispatch($child/node())
          }
};

declare
function _:inline( $tag as xs:string, $node as node()* ) as item()* {
element {$tag}{ 
 for $child in $node
 return _:dispatch($child/node())
 }
};

declare
function _:block( $tag as xs:string, $node as node()* ) as item()* {
element {$tag}{ 
 for $child in $node
 return _:dispatch($child/node())
 }
};

declare
function _:image( $node as node()* ) as item()* {
element img {
    attribute src { $node/@destination/string() },
    attribute title { $node/@title/string() },
    attribute alt { $node/cm:text/string() }
 }
};

declare
function _:document( $node as node()* ) as item()* {
element article {
 for $child in $node
 return _:dispatch($child/node())
 }
};

declare
function _:list( $node as node()* ) as item()* {
if ($node/@type = 'bullet'  ) 
then 
element ul {
 for $child in $node
 return _:dispatch($child/node())
 }
else
element ol {
 for $child in $node
 return _:dispatch($child/node())
 }
};

declare
function _:htmlBlock( $node as node()* ) as item()* {
try{
 if (not( starts-with(normalize-space( $node/string() ),'&lt;!--'))) 
 then () (:$node/string() => util:parse():)
 else ()
 } catch * {()}
};

(: TODO! @info code :)
declare
function _:codeBlock( $node as node()* ) as item()* {
element pre {
    element code {
        if ( $node/@info  )  
        then ( attribute class { 'language-' || $node/@info/string() })
        else (),
        for $child in $node
        return _:dispatch($child/node())
    }
 }
};

declare
function _:heading( $node as node()* ) as item()* {
element { concat('h', $node/@level/string() )  } {
 for $child in $node
 return _:dispatch($child/node())
 }
};

declare
function _:link( $node as node()* ) as item()* {
element a { attribute href { $node/@destination },
            attribute title { $node/@title }, 
            normalize-space( $node/string() ) 
           }
};
