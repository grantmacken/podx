function( $map) {
	element html {
		attribute lang {'en'},
		element head {
			element title { $map?title }
		},
		element body {
			element h1 {  $map?title },
			element main { $map?content/node() }
		}
	}
}
