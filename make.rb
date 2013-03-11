require "fileutils"
require "yaml"
require "erb"
include ERB::Util

# Models
class Blog
  attr_reader :posts
  
  def initialize
    @posts = []
    Dir.foreach("posts") do |file_name|
      if File.extname(file_name) == ".html"
        @posts << Post.new(File.basename(file_name, ".html"))
      end
    end
    @posts.sort! {|a, b| - (a.date <=> b.date)}
  end
end

class Post
  attr_reader :name, :author, :date, :content, :url
  
  def initialize(name)
    file_name = "posts/#{name}.html"
    if /\A(\d+)-(\d+)-(\d+)-(\w+)-(.*)\z/ === name
      @date = Time.local($1, $2, $3)
      @author = $4
      @name = $5
    else
      raise "Invalid post name \"#{file_name}\". Should be YEAR-MONTH-DAY-AUTHOR-TITLE.html"
    end
    @content = File.read(file_name)
    @url = "blog/#{@name.gsub(/\W/, "-").downcase}.html"
  end
end

# Views
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

module Helpers
  def header(config, dir, active_link)
    Template.new("helpers/header.rhtml").result(binding)
  end
  
  def footer
    Template.new("helpers/footer.rhtml").result(binding)
  end
  
  def date(time)
    Template.new("helpers/date.rhtml").result(binding)
  end
  
  def post_content(config, dir, post, preview, comments)
    Template.new("helpers/post_content.rhtml").result(binding)
  end
  
  def quick_links
  Template.new("helpers/quick_links.rhtml").result(binding)
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

# Controller
class Controller
  def initialize(config)
    @config = config
    @blog = Blog.new
  end
  
  def make
    FileUtils.mkdir_p("#{@config["destination"]}/blog")
    FileUtils.cp_r(["css", "img", "js"], "#{@config["destination"]}/")
    
    pages = ["site/*.rhtml", "site/rss.rxml"]
    pages = (pages.map {|name| Dir.glob(name)}).flatten
    page_views = pages.collect {|file_name| PageView.new(@blog, @config, file_name)}
    post_views = @blog.posts.collect {|post| PostView.new(@blog, @config, post)}
    
    for view in page_views + post_views do
      File.open("#{@config["destination"]}/#{view.url}", "w") {|f| f << view.html}
    end
  end
end

# Run
config = YAML::load_file("config.yaml")
Controller.new(config).make
