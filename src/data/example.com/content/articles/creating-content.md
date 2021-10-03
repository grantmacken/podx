# creating content

Page main body content

 content is created thru markdown text
 text is converted to a cmark document and put into the xqerl db.

xQuery templates

On our site we may have a collection of articles.
The src files for these are articles are in `src/data/example.com/content/articles`
The default template for the collection will be named `default.xq`
If needed, say for the article collection `index page`, the xquery template file will be named 
after the basename of the markdown file and be named `index.xq`

In the example below we have a collection of source files in the articles directory.
Page template consists of a xquery function.
The function itself contain either direct element or computed element constructors
example: 

