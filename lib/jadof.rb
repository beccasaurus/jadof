$LOAD_PATH.unshift File.dirname(__FILE__)

require 'indifferent-variable-hash'

module JADOF

  module PageAPI

    # The root directory that pages are loaded from
    attr_accessor :dir

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
    attr_accessor :formatters

    @formatters = {}

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
    attr_accessor :cache

    def cache_for key, &block
      return block.call unless cache

      from_cache = cache.get(key)
      unless from_cache
        from_cache = block.call
        cache.set(key, from_cache)
      end
      from_cache
    end

    # Get a Page by name
    def get name
      first :full_name => name.to_s
    end

    alias [] get

    # Get all Pages in Page.dir
    def all
      cache_for 'all' do
        Dir[ File.join(dir, "**/*") ].reject {|path| File.directory?(path) }.map {|path| from_path(path) }
      end
    end

    # Returns the count of all Pages
    def count
      all.length
    end

    # Gets pages given some simple conditions (only == equality is supported)
    def where conditions
      all.select { |page| matches_conditions? page, conditions }
    end

    # Gets a page given some simple conditions
    def first conditions
      all.find { |page| matches_conditions? page, conditions }
    end

    # Helper for #where and #first
    def matches_conditions? page, conditions
      matches = true
      conditions.each {|k,v| matches = false unless page.send(k) == v }
      matches
    end

    # Loads a Page from a given path to a file
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

      Page.new variables
    end

    # Using the #filename of the page given and available Page.formatters, 
    # we render and return the page #body.
    def to_html page
      html = page.body

      page.filename.scan(/\.([^\.]+)/).reverse.each do |match| # [ ["markdown"], ["erb"] ]
        if formatter = Page.formatters[ match.first ]
          html = formatter.call(html)
        end
      end

      html
    end

  end

  class Page
    extend  PageAPI
    include IndifferentVariableHash

    # These are the default attributes that all pages have
    #
    # TODO add comments for each accessor describing how it is used
    attr_accessor :name, :path, :filename, :body, :parent

    def initialize options = nil
      options.each {|attribute, value| send "#{attribute}=", value } if options
    end

    def full_name
      parent == '' ? name : File.join(parent, name)
    end

    def to_html
      self.class.to_html self
    end
  end

end
