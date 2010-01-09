module JADOF

  module PageMethods

    # The root directory that pages are loaded from
    attr_accessor :dir

    # Get a Page by name
    def get name
      matches = Dir[ File.join dir, "#{ name }.*" ]
      case matches.length
      when 0
        nil
      when 1
        from_path matches.first
      else
        raise "Ambiguous page name #{ name } matches: #{ matches.inspect }"
      end
    end

    alias [] get

    # Get all Pages in Page.dir
    def all
      Dir[ File.join(dir, "**/*") ].map {|path| from_path(path) }
    end

    # Returns the count of all Pages
    def count
      all.length
    end

    # Loads a Page from a given path to a file
    def from_path path
      filename = File.basename path
      name     = filename[/^[^\.]+/] # get everything before a .
      body     = File.read path

      Page.new :name => name, :path => path, :filename => filename, :body => body
    end

  end

  class Page
    extend PageMethods

    # These are the default attributes that all pages have
    attr_accessor :name, :path, :filename, :body

    def initialize options = nil
      options.each {|attribute, value| send "#{attribute}=", value } if options
    end

  end

end
