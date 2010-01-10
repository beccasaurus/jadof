module JADOF #:nodoc:

  # A {Page} wraps a file on the filesystem.
  #
  # If you set {Page.dir} to a directory, {Page.all} will 
  # give you all of the files inside that directory as {Page} 
  # objects.
  #
  class Page
    include IndifferentVariableHash

    # @return [String] A simple name for this {Page}.
    #
    # If the filename is `foo.markdown`, the name will be `foo`
    # 
    # If the file is in a subdirectory below {Page.dir}, eg. 
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
    # in a subdirectory below {Page.dir}.  This will be `""` if 
    # it is in {Page.dir} or it will be `"sub/directories"` if
    # it is in subdirectories.
    attr_accessor :parent

    # A page is a dumb object and doesn't know how to load itself from 
    # a file on the filesystem.  See {Page.from_path} to load a {Page} 
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

    # Returns the formatted {#body} of this {Page} using {Page.formatters}.
    #
    # The file extensions from the {#filename} are used to match formatters.
    #
    # For `foo.markdown`, `Page.formatters['markdown']` will be used.
    # For `foo.markdown.erb`, `Page.formatters['erb']` and `Page.formatters['markdown']` will be used.
    #
    # With multiple extensions, the *last* extension is used first, and then the second-to-last, etc.
    def to_html
      self.class.to_html self
    end

    class << self

      # @return [String] The root directory that pages are loaded from.  Defaults to "./posts/"
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

    end

    @dir ||= './posts/' # default Page.dir

    # When dir is set, we save it as an expanded path.
    # We also clear the cache (if it's enabled)
    def self.dir= value
      cache.clear if cache
      @dir = File.expand_path value
    end

    # A Hash of available formatters.  The key is used to match 
    # a given file extension and the value should be something 
    # that you can #call (like a lambda) with text which returns 
    # the formatted text.
    # @return [Hash{String => #call}]
    def self.formatters
      @formatters || {}
    end

    # @return [Page] Get a Page by name
    def self.get name
      first :full_name => name.to_s
    end

    # @return [Page] Alias for Page.get
    def self.[] name
      get name
    end

    # @return [Array(Page)] Get all Pages in Page.dir
    def self.all
      cache_for 'all' do
        Dir[ File.join(dir, "**/*") ].reject {|path| File.directory?(path) }.map {|path| from_path(path) }
      end
    end

    # @return [Fixnum] Returns the count of all Pages
    def self.count
      all.length
    end

    # @return [Array(Page)] Gets pages given some simple conditions (only == equality is supported)
    def self.where conditions
      all.select { |page| matches_conditions? page, conditions }
    end

    # @return [Page, nil] Gets a page given some simple conditions
    def self.first conditions
      all.find { |page| matches_conditions? page, conditions }
    end

    # @return [Page] Loads a Page from a given path to a file
    def self.from_path path
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

    # @return [String] Using the #filename of the page given and available 
    # Page.formatters, we render and return the page #body.
    def self.to_html page
      html = page.body

      page.filename.scan(/\.([^\.]+)/).reverse.each do |match| # [ ["markdown"], ["erb"] ]
        if formatter = Page.formatters[ match.first ]
          html = formatter.call(html)
        end
      end

      html
    end

    # @private
    # Helper for caching.  Will check to see if the {Page.cache} 
    # contains the given key and, if not, it will set the cache by calling
    # the block given
    def self.cache_for key, &block
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
    def self.matches_conditions? page, conditions
      matches = true
      conditions.each {|k,v| matches = false unless page.send(k) == v }
      matches
    end

  end

end
