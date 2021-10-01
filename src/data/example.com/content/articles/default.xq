function( $map) {
	element html {
		attribute lang {'en'},
		element head {
      element meta {
        attribute http-equiv { "Content-Type"},
        attribute content { "text/html; charset=UTF-8"}
        },
      element title { $map?title },
      if ( $map => map:contains('summary') ) then 
      element meta {
        attribute name { 'description' },
        attribute content { $map?summary }
      }
      else (),
      element meta {
        attribute name { 'viewport' },
        attribute content { 'width=device-width, initial-scale=1' }
      },
      element link {
        attribute href { $map?url },
        attribute rel { 'self' },
        attribute type { 'text/html' }
      }
    },
    element body {
			element h1 {  $map?title },
			element main { $map?content/node() },
      element footer {
        attribute title { 'page footer' },
        attribute role  { 'contentinfo' },
        element a {
          attribute href { 'https://' || $map?domain },
          $map?domain,
          ' - a website owned, authored and operated by&#8239;' ,
          element a {
            attribute href { $map?uri },
            attribute title {'author'},
            $map?site-author
          }
        }
      }
    }
  }
}
