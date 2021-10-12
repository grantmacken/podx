xquery version "3.1";
module namespace _ = "http://xq/#cmarkup";
declare namespace cm ="http://commonmark.org/xml/1.0";

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
