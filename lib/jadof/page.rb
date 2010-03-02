module JADOF #:nodoc:

  # This is the class interface for {Page}.
  #
  # This is split out into a separate module so we can 
  # extend other classes (that inherit from Page) with 
  # this.
  #
  # Actually, if you inherit from Page, you automatically 
  # get this module extended into your class.
  module PageAPI

    # @return [String] The root directory that pages are loaded from.  Defaults to "./pages/"
    attr_accessor :dir

    attr_accessor :formatters

    # This can be set to a standard cache object and, if it is set, 
    # all pages will be cached so they don't have to be re-opened 
    # and we don't have to look for the files.
    #
    # Any cache object that supports these standard methods is supported:
    #   
    #   get(key)
    #   set(key, value)
    #   clear
    #
    # @return [#get, #set, #clear]
    attr_accessor :cache

    def dir
      @dir ||= File.expand_path JADOF::Page::DEFAULT_DIR
    end

    # When dir is set, we save it as an expanded path.
    # We also clear the cache (if it's enabled)
    def dir= value
      cache.clear if cache
      @dir = File.expand_path value
    end

    # A Hash of available formatters.  The key is used to match 
    # a given file extension and the value should be something 
    # that you can #call (like a lambda) with text which returns 
    # the formatted text.
    # @return [Hash{String => #call}]
    def formatters
      @formatters ||= JADOF::Page::DEFAULT_FORMATTERS
    end

    # @return [Page] Get a Page by name
    def get name
      first :full_name => name.to_s
    end

    # @return [Page] Alias for Page.get
    def [] name
      get name
    end

    # @return [Array(Page)] Get all Pages in Page.dir
    def all conditions = nil
      pages = cache_for 'all' do
        Dir[ File.join(dir, "**/*") ].reject {|path| File.directory?(path) }.map {|path| from_path(path) }
      end
      conditions.nil? ? pages : where(conditions)
    end

    # @return [Fixnum] Returns the count of all Pages
    def count
      all.length
    end

    # @return [Page, nil] Returns the last Page
    def last
      all.last
    end

    # @return [Array(Page)] Gets pages given some simple conditions (only == equality is supported)
    def where conditions
      all.select { |page| matches_conditions? page, conditions }
    end

    # @return [Page, nil] Gets a page given some simple conditions
    def first conditions = nil
      if conditions
        all.find { |page| matches_conditions? page, conditions }
      else
        all.first
      end
    end

    # @return [Page] Loads a Page from a given path to a file
    def from_path path
      path      = File.expand_path path
      filename  = File.basename path
      name      = filename[/^[^\.]+/] # get everything before a .
      body      = File.read path

      # Remove YAML from top of body and get the YAML variables from it.
      # Then we can merge in the name, path, etc, and use it to inialize a page
      body.sub! /^---(.*)\n---\n/m, ''
      variables = $1 ? YAML.load($1) : {}
      variables.merge! :name => name, :path => path, :filename => filename, :body => body

      # If the file is in a subdirectory, get the name of the subdirectory[ies] 
      # and set it as :parent, so it's easily accessible from the Page.
      # Also, we strip the first and last '/' characters off of it.
      variables[:parent] = File.dirname(path).sub(dir, '').sub(/^\//, '')

      new variables
    end

    # @return [String] Using the #filename of the page given and available 
    # Page.formatters, we render and return the page #body.
    def render page
      html = page.body

      page.extensions.reverse.each do |extension| # ["markdown", "erb"]
        if formatter = formatters[extension]
          begin
            html = formatter.call(html)
          rescue ArgumentError => ex
            if ex.message == 'wrong number of arguments (1 for 2)'
              html = formatter.call(html, page)
            else
              raise
            end
          end
        end
      end

      html
    end

    alias to_html render

    # @private
    # Helper for caching.  Will check to see if the {Page.cache} 
    # contains the given key and, if not, it will set the cache by calling
    # the block given
    def cache_for key, &block
      return block.call unless cache

      from_cache = cache.get(key)
      unless from_cache
        from_cache = block.call
        cache.set(key, from_cache)
      end
      from_cache
    end

    # @private 
    # @return [true, false] Helper for #where and #first
    def matches_conditions? page, conditions
      matches = true
      conditions.each {|k,v| matches = false unless page.send(k) == v }
      matches
    end

    # @private
    # When a class inheritcs from Page (or from any class that inherits page), 
    # we extend that class with {PageAPI} so it will get methods like `Page.all`.
    def inherited base
      base.extend PageAPI
    end
  end

  # A {Page} wraps a file on the filesystem.
  #
  # If you set `Page.dir` to a directory, `Page.all` will 
  # give you all of the files inside that directory as {Page} 
  # objects.
  #
  # For all of the available class methods, see {PageAPI}.
  #
  class Page
    extend  PageAPI
    include IndifferentVariableHash

    DEFAULT_DIR = './pages/'

    DEFAULT_FORMATTERS = {
      'markdown' => lambda { |text| require 'maruku';   Maruku.new(text).to_html      },
      'erb'      => lambda { |text| require 'erb';      ERB.new(text).result          },
      'haml'     => lambda { |text| require 'haml';     Haml::Engine.new(text).render },
      'textile'  => lambda { |text| require 'redcloth'; RedCloth.new(text).to_html    }
    }

    # @return [String] A simple name for this {Page}.
    #
    # If the filename is `foo.markdown`, the name will be `foo`
    # 
    # If the file is in a subdirectory below `Page.dir`, eg. 
    # `foo/bar.markdown`, the name will be `bar` but the 
    # #full_name will be `foo/bar`.
    attr_accessor :name

    # @return [String] The full system path to this file
    attr_accessor :path

    # @return [String] The filename (without a directory), eg. `foo.markdown`
    attr_accessor :filename

    # @return [String] The body of the file, *without* the YAML at 
    # the top of the file (if YAML was included).
    #
    # We strip out the YAML and use it to set variables on 
    # the Page.  If you need the *full* text from the file, 
    # you should `File.read(@page.path)`.
    attr_accessor :body

    # @return [String] The parent directory of this file, if this file is 
    # in a subdirectory below `Page.dir`.  This will be `""` if 
    # it is in `Page.dir` or it will be `"sub/directories"` if
    # it is in subdirectories.
    attr_accessor :parent

    # @return [Array(String)] This file's extension(s).
    def extensions
      filename.scan(/\.([^\.]+)/).flatten
    end

    # A page is a dumb object and doesn't know how to load itself from 
    # a file on the filesystem.  See `Page.from_path` to load a {Page} 
    # from a file.
    #
    # @param [Hash] of attributes
    def initialize options = nil
      options.each {|attribute, value| send "#{attribute}=", value } if options
    end

    # @return [String] combines {#name} with {#parent}
    def full_name
      parent == '' ? name : File.join(parent, name)
    end

    # Returns the formatted {#body} of this {Page} using `Page.formatters`.
    #
    # The file extensions from the {#filename} are used to match formatters.
    #
    # For `foo.markdown`, `Page.formatters['markdown']` will be used.
    # For `foo.markdown.erb`, `Page.formatters['erb']` and `Page.formatters['markdown']` will be used.
    #
    # With multiple extensions, the *last* extension is used first, and then the second-to-last, etc.
    def render
      self.class.render self
    end

    alias to_html render

    # @return [true, false] If 2 pages have the same system path, they're the same.
    def == other_page
      return false unless other_page.is_a? Page
      return other_page.path == path
    end

    # @return [String] This page as a string.  Defaults to {#full_name}.
    def to_s
      full_name
    end

    # @return [String] A param representation of this page for us in web applications.  Defaults to {#full_name}.
    def to_param
      full_name
    end

  end

end
