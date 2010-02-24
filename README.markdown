JADOF
=====

**{JADOF}** is **J**ust **a** **D**irectory **o**f **F**iles

As a coder, I like my blog/cms sites to be simple and database-free.

Like some other coders, I prefer to edit my blog posts in my preferred 
text editor.  Typically, I put abunchof [markdown][] files in a directory 
and put a web interface infront of it.

So ... I'm taking the tiny class that I typically use to wrap my blog 
posts and releasing it as a micro library incase anyone else finds it useful!

Installation & Usage
--------------------

If you prefer video documentation, check out the screencast!  [http://remi.org/.../](#)

### Install ...

    $ sudo gem install jadof

### Use ...

    $ mkdir pages
    $ echo "*Hello* __World__" > pages/hello-world.markdown
    $ irb
    >> require 'jadof'
    => true
    >> JADOF::Page.count
    => 1
    >> JADOF::Page.first
    => #<JADOF::Page:0x7f3665d13920 @parent="", @body="*Hello* __World__\n", @filename="hello-world.markdown", @name="hello-world", @path="/home/remi/desktop/pages/hello-world.markdown">
    >> JADOF::Page.first.name
    => "hello-world"
    >> JADOF::Page.first.body
    => "*Hello* __World__\n"
    >> JADOF::Page.first.to_html
    => "<p><em>Hello</em> <strong>World</strong></p>"

### Find pages ...

    $ touch pages/{hello-world,foo,bar,hello,world}
    $ irb -r jadof
    >> JADOF::Page.all.length
    => 5
    >> JADOF::Page.all.map {|page| page.name }
    => ["hello", "foo", "world", "hello-world", "bar"]
    >> JADOF::Page.all(:name => 'foo')
    => [#<JADOF::Page:0x7faac2bce1d8 @parent="", @body="", @name="foo", @path="/home/remi/desktop/pages/foo", @filename="foo">]
    >> JADOF::Page.first(:name => 'foo')
    => #<JADOF::Page:0x7faac2acd630 @parent="", @body="", @name="foo", @path="/home/remi/desktop/pages/foo", @filename="foo">
    >> JADOF::Page.get('foo')
    => #<JADOF::Page:0x7faac2a27cd0 @parent="", @body="", @name="foo", @path="/home/remi/desktop/pages/foo", @filename="foo">
    >> JADOF::Page[:foo]
    => #<JADOF::Page:0x7faac30e1e90 @parent="", @body="", @name="foo", @path="/home/remi/desktop/pages/foo", @filename="foo">

### Add meta-data to your pages via YAML ...

    $ cat pages/foo
    ---
    hi:  there
    num: 5.10
    tags:
    - this
    - that
    date: 2010-01-31
    ---

    Page with meta-data!
    $ irb -r jadof
    >> JADOF::Page.get(:foo)
    => #<JADOF::Page:0x7fdde7b47fe0 @parent="", @variables={"hi"=>"there", "tags"=>["this", "that"], "date"=>#<Date: 4910455/2,0,2299161, "num"=5.1}, @body="\nPage with meta-data!\n", @name="foo", @path="/home/remi/desktop/pages/foo", @filename="foo">
    >> JADOF::Page.get(:foo).variables
    => {"hi"=>"there", "tags"=>["this", "that"], "date"=>#<Date: 4910455/2,0,2299161>, "num"=>5.1}
    >> JADOF::Page.get(:foo).hi
    => "there"
    >> JADOF::Page.get(:foo).tags
    => ["this", "that"]
    >> JADOF::Page.get(:foo).date
    => #<Date: 4910455/2,0,2299161>
    >> JADOF::Page.get(:foo).num
    => 5.1

### Create your own "formatters" ...

    $ echo "Hello World" > pages/foo.upcase
    $ echo "Hello World" > pages/bar.underline
    $ echo "Hello World" > pages/test.underline.upcase
    $ irb -r jadof
    >> include JADOF
    => Object
    >> Page.all.map &:name
    => ["bar", "test", "foo"]

    >> Page[:foo].to_html
    => "Hello World\n"
    >> Page.formatters.keys
    => ["markdown", "erb"]
    >> Page.formatters['upcase'] = lambda {|text| text.upcase }
    => #<Proc:0x00007ffc6e2f44b0@(irb):7>
    >> Page[:foo].to_html
    => "HELLO WORLD\n"

    >> Page[:bar].to_html
    => "Hello World\n"
    >> Page.formatters['underline'] = lambda {|text| "__#{ text.gsub(' ','__') }__" }
    => #<Proc:0x00007ffc6e2d0920@(irb):12>
    >> Page[:bar].to_html
    => "__Hello__World\n__"

    >> Page[:test].body
    => "Hello World\n
    >> Page[:test].to_html
    => "__HELLO__WORLD\n__"

[markdown]: http://en.wikipedia.org/wiki/Markdown
