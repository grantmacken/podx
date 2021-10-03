function($map) {
  element html {
    attribute lang {'en'},
    element head {
      element title { $map?site-title }
    },
    element body {
      element header { element h1 { $map?title }},
      element main { $map?content/node()},
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

