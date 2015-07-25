# PuPuS blog:

    ruby make.rb
  
## Add a post
### `posts/`
The blog posts. The convention is `YEAR-MONTH-DAY-AUTHOR-TITLE.rhtml`. Modify `config.yaml` to add authors. Content is pure HTML. You can use:

    <% unless preview %>
      ...
    <% end %>

to mark the part which will not be displayed on the front page.
    
### `data/`
The repository to put various data such as pictures.
  
## Modify the blog system
* `css/` [Bootstrap CSS](http://getbootstrap.com/) + a customized `style.css`;
* `font/` [Font Awsome](http://fortawesome.github.io/Font-Awesome/) icon set;
* `helpers/` HTML snippets included in other pages;
* `js/` Bootstrap JavaScript;
* `site/` the web pages of the site in Ruby-HTML `.rhtml`. They will be compiled to pure `.html` files;
* `config.yaml` settings: global parameters and the list of the blog authors;
* `make.rb` the main file to run everything.

## Technologies
HTML templates in Ruby + [Bootstrap CSS](http://getbootstrap.com/).
