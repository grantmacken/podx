function( $map) {
	element html {
		attribute lang {'en'},
		element head {
      element meta {
        attribute http-equiv { "Content-Type"},
        attribute content { "text/html; charset=UTF-8"}
        },
      element title { $map?item  || ": " || $map?collection  || " page"},
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
      },
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
        },
      element link {
        attribute href { '/styles/index' }
        },
      element script {
        attribute src { '/scripts/prism' }
        }
      },
    element body {
      element header { 
        attribute role { 'banner' },
        element h1 { 
          if ( $map => map:contains('title'))
          then $map?title
          else
            if( $map?item = 'index') 
            then  ($map?domain,$map?collection,$map?item => translate('-', ' '),' page')
            else $map?item => translate('-', ' ')
          }
        },
      element nav {
        attribute aria-label { 'Breadcrumb' },
        attribute class { 'nl' },
        element ul {
          attribute class { 'nl_breadcrumb' },
           ( $map?uri => 
                substring-after('://') =>
                fn:tokenize('/')
              ) ! 
              element li { 
                element a {
                  if ( $map?item = . ) 
                  then ( attribute  aria-current { 'page' })
                  else (),
                  attribute href {
                    concat('/',
                    concat($map?uri => substring-before( . ), .) 
                    => substring-after($map?base-uri || '/')) 
                  },
                  .
                } 
              }
            }
        },
      element main { 
        element article { 
          $map?content/node()
          },
        element aside { 
          element nav { 
            element h2 {
              attribute id { 'articles' },
              ``[ site articles ]``  
              },
            element ul { 
              ( 'http://example.com/content/articles' => 
              uri-collection() =>
              filter( function($str){ ends-with($str,'.cmark') and not(ends-with($str,'index.cmark'))})
              ) !
              element li  {
                element a  {
                  attribute href { . => substring-after('/content') => substring-before('.') },
                  . => substring-after('/articles/') => substring-before('.') => translate('-', ' ' )
                  }
                }
              }
            }
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
