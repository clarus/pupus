require "fileutils"
require "yaml"
require "erb"
include ERB::Util

class Template
  def initialize(file_name)
    @file_name = file_name
    @erb = ERB.new(File.read(@file_name))
  end
  
  def result(binding)
    begin
      @erb.result(binding).gsub(/^\s*$\n/, "").chomp
    rescue => e
      puts "from \"#{@file_name}\""
      raise e
    end
  end
end

# Models
class Blog
  attr_reader :posts, :nb_pages
  
  def initialize(config)
    @posts = []
    Dir.foreach("posts") do |file_name|
      if File.extname(file_name) == ".rhtml"
        @posts << Post.new(File.basename(file_name, ".rhtml"))
      end
    end
    @posts.sort! {|a, b| - (a.date <=> b.date)}
    a = @posts.size; b = config["posts_per_page"]
    @nb_pages = a / b + (a % b == 0 ? 0 : 1)
  end
end

class Post
  attr_reader :name, :author, :date, :content, :content_preview, :url
  
  def initialize(name)
    file_name = "posts/#{name}.rhtml"
    if /\A(\d+)-(\d+)-(\d+)-(\w+)-(.*)\z/ === name
      @date = Time.local($1, $2, $3)
      @author = $4
      @name = $5
    else
      raise "Invalid post name \"#{file_name}\". Should be YEAR-MONTH-DAY-AUTHOR-TITLE.rhtml"
    end
    preview = false
    @content = Template.new(file_name).result(binding)
    preview = true
    @content_preview = Template.new(file_name).result(binding)
    @url = "blog/#{@name.gsub(/\W+/, "-").downcase}.html"
  end
end

# Views
module Helpers
  def header(config, dir, active_link)
    Template.new("helpers/header.rhtml").result(binding)
  end
  
  def footer(config, dir)
    Template.new("helpers/footer.rhtml").result(binding)
  end
  
  def post_content(config, dir, post, preview, comments)
    Template.new("helpers/post_content.rhtml").result(binding)
  end
end

class View
  include Helpers
  attr_reader :url, :html
end

class PageView < View
  def initialize(blog, config, file_name)
    extension = File.extname(file_name)
    @url = "#{File.basename(file_name, extension)}.#{extension[2..-1]}"
    @html = Template.new(file_name).result(binding)
  end
end

class PostView < View
  def initialize(blog, config, post)
    @url = post.url
    @html = Template.new("helpers/post.rhtml").result(binding)
  end
end

class PostsView < View
  def initialize(blog, config, page)
    @url = link_to_page(page)
    @html = Template.new("helpers/posts.rhtml").result(binding)
  end
  
  def link_to_page(page)
    "index#{page == 0 ? "" : page + 1}.html"
  end
end

# Controller
class Controller
  def initialize(config)
    @config = config
    @blog = Blog.new(@config)
  end
  
  def make
    FileUtils.mkdir_p("#{@config["destination"]}/blog")
    FileUtils.cp_r(["css", "img", "js"], "#{@config["destination"]}/")
    
    pages = ["site/*.rhtml", "site/rss.rxml"]
    pages = (pages.map {|name| Dir.glob(name)}).flatten
    page_views = pages.collect {|file_name| PageView.new(@blog, @config, file_name)}
    post_views = @blog.posts.collect {|post| PostView.new(@blog, @config, post)}
    
    posts_views = Array.new(@blog.nb_pages) {|page| PostsView.new(@blog, @config, page)}
    views = page_views + post_views + posts_views
    
    for view in views do
      File.open("#{@config["destination"]}/#{view.url}", "w") {|f| f << view.html}
    end
    puts "#{views.size} files generated."
  end
end

# Run
config = YAML::load_file("config.yaml")
Controller.new(config).make
