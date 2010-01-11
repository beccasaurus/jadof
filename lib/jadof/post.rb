require 'time'

module JADOF #:nodoc:

  # Represents a blog post.  Has the same functionality as {Page} 
  # but with a {#date} added (which makes {#to_param}) include 
  # a date, in the conventional way: `2010/01/31/name-of-post`
  class Post < Page

    # @return [Time] the date that this post was created.
    # If a [String] is passed in, it will be parsed as a time.
    attr_accessor :date

    def date= value
      @date = Time.parse value.to_s
    end

    # @return [String] The conventional way to display blog 
    # post urls, eg. `2010/01/31/name-of-post`
    def to_param
      date ? "#{ date.strftime('%Y/%m/%d') }/#{ full_name }" : super
    end

  end

end
