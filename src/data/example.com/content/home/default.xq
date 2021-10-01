function($map) {
  element html {
    attribute lang {'en'},
    element head {
      element title { $map?site-title }
    },
    element body {
      element header { element h1 { $map?title }},
      element main { $map?content/node()},
      element footer { 'my footer' }
    }
  }
}

