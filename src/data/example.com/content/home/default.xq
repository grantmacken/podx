function($map) {
  element html {
    attribute lang {'en'},
    element head {
      element meta {
        attribute http-equiv { "Content-Type"},
        attribute content { "text/html; charset=UTF-8"}
        },
      element title { $map?site-title },
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
        }, (:
      element link {
        attribute href { '/fonts/ibm-plex-sans-v7-latin-regular.woff2' },
        attribute rel { 'preload' },
        attribute as { 'font' },
        attribute type { 'font/woff2' }
        },
        :)
      element link {
        attribute href { '/styles/fonts' },
        attribute rel { 'preload' },
        attribute as { 'style' },
        attribute type { 'text/css' }
        },
      element link {
        attribute href { '/styles/index' },
        attribute rel { 'stylesheet' },
        attribute type { 'text/css' }
        }
      },
    element body {
      element header { 
        attribute role { 'banner' },
        element h1 { $map?title }
        },
      element main { 
        element article { 
          $map?content/node()
          }
        },
      element footer {
        attribute title { 'page footer' },
        attribute role  { 'contentinfo' },
        element a {
          attribute href { '/' },
          $map?domain
          },
        ' - a website owned, authored and operated by&#8239;' ,
        element a {
          attribute href { '/' },
          attribute title {'author'},
          $map?site-author
        }
      }
    }
  }
}

