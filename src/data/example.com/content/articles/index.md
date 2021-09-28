src content pattern: src/data/{domain}/content/{collection}/{item}
db stored as pattern: {domain}/content/{collection}/{item}

 - commonmark doc => xml cmark doc 
    site home page: {domain}/content/home/index.cmark 
    topic index page: {domain}/content/articles/index.cmark 
    topic item page: {domain}/content/articles/interesting-article.cmark 
 
 - template files as xquery direct or direct element constructors 
   => stored as a XDM function items
    collection templates:
        - site home page: {domain}/content/home-index 
        - index page for collection: {domain}/content/articles-index
        - index page for collection: {domain}/content/articles
        - template specific to page: {domain}/content/articles/my-special-page

- supporting template JSON files
   => stored as a XDM map items
    site home page map: {domain}/content/home/index.map
    topic index page map: {domain}/content/articles/index.map
    topic item page map: {domain}/content/articles/interesting-article.map
 in addition to the above
    site-wide every page map: {domain}/content/site.map
    every item in a collection: {domain}/content/articles.map
  note: the site wide map
  
The map argument given to the template function is created by merging the above stored XDM map items

