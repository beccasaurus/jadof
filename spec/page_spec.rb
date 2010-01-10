require File.dirname(__FILE__) + '/spec_helper'

require 'fileutils'
require 'hash-cache'

# Helper for creating page files in the specs, at spec/pages/
def create_page filename, body = '', page_dir = Page.dir
  body.sub!("\n", '')     if body.lines.first == "\n" # get rid of first empty line
  body.sub!(/\n\s+$/, '') if body.lines.count > 0     # get rid of last  empty line

  # grab the spaces (if any) from the 1st line and remove that
  # many spaces from the rest of the lines so our specs look clean
  if body.lines.first
    spaces = body.lines.first[/^[ ]+/]
    body.gsub!(/^#{spaces}/, '') if spaces
  end

  body ||= '' # if it's nil for some reason, make it an empty string

  path = File.join(page_dir, filename)
  FileUtils.mkdir_p File.dirname(path)
  File.open(path, 'w'){|f| f << body }
end

# Helper for deleting all pages in spec/pages/
def delete_pages
  Dir[File.join(Page.dir, '**/*')].each do |page|
    FileUtils.rm_rf page
  end
end

describe Page do

  before do
    Page.dir = File.dirname(__FILE__) + '/pages'
    delete_pages
  end

  after :all do
    delete_pages # clean up!
  end

  it '#create_page works as expected for creating fake pages for these specs' do
    path = File.dirname(__FILE__) + '/pages/foo.markdown'
    File.file?(path).should be_false

    create_page 'foo.markdown'

    File.file?(path).should be_true
    Page[:foo].body.should == ''

    create_page 'foo.markdown', %{
      it should fix
        the spaces
      for me
    }

    Page[:foo].body.should == "it should fix\n  the spaces\nfor me"
  end

  it 'can set the Page.dir to specify the directory to fetch pages from' do
    dir1, dir2 = Page.dir, File.dirname(__FILE__) + '/more_pages'

    create_page 'foo.markdown', 'hello world', dir1
    create_page 'bar.markdown', 'hello world', dir2

    Page[:foo].should_not be_nil
    Page[:bar].should     be_nil

    Page.dir = dir2

    Page[:foo].should     be_nil
    Page[:bar].should_not be_nil
  end

  it 'has a filename (the actual filename, without a path)' do
    create_page 'foo.markdown'

    Page[:foo].should_not be_nil
    Page[:foo].filename.should == 'foo.markdown'
  end

  it 'has a path (the full system path to the file)' do
    create_page 'foo.markdown'

    Page[:foo].should_not be_nil
    Page[:foo].path.should == File.expand_path(File.dirname(__FILE__) + '/pages/foo.markdown')
  end

  it 'has a name (the name of the file, without extensions)' do
    create_page 'foo.markdown'

    Page[:foo].should_not be_nil
    Page[:foo].name.should == 'foo'
  end

  it 'has a body (the content of the file)' do
    create_page 'foo.markdown'
    Page[:foo].body.should == ''

    create_page 'foo.markdown', %{
      Hello World!
    }

    Page[:foo].body.strip.should == 'Hello World!'
  end

  it 'can return all pages' do
    Page.count.should      == 0
    Page.all.length.should == 0

    create_page 'foo.markdown'
    
    Page.count.should      == 1
    Page.all.length.should == 1
  end

  it 'can get a page by name' do
    Page.get(:foo).should be_nil
    Page[:foo].should     be_nil

    create_page 'foo.markdown'

    Page.get(:foo).should_not be_nil
    Page[:foo].should_not     be_nil
  end

  it 'can add any kind of arbitrary data to a page via YAML' do
    create_page 'foo.markdown'
    Page[:foo].foo.should be_nil # Page's don't raise NoMethodError's

    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    Page[:foo].foo.should == 'bar' # got value from YAML
  end

  it 'can get a page by the value of any arbitrary data (from the YAML)' do
    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    Page.first(:foo => 'not bar').should     be_nil
    Page.first(:foo => 'bar'    ).should_not be_nil
    Page.first(:foo => 'bar'    ).foo.should == 'bar'
  end

  it 'can get a page by *multiple* arbitrary conditions' do
    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    Page.where(:foo => 'bar', :name => 'not foo').should be_empty
    Page.where(:foo => 'not bar', :name => 'foo').should be_empty
    Page.where(:foo => 'bar', :name => 'foo').should_not be_empty
    Page.where(:foo => 'bar', :name => 'foo').first.name.should == 'foo'
  end

  it 'supports 1 level of sub-directories' do
    create_page 'hi.markdown'
    Page['hi'].parent.should == ''

    create_page 'foo/bar.markdown'

    Page['foo/bar'].name.should      == 'bar'
    Page['foo/bar'].full_name.should == 'foo/bar'
    Page['foo/bar'].parent.should    == 'foo'
    Page['foo/bar'].filename.should  == 'bar.markdown'
    Page['foo/bar'].path.should include('foo/bar.markdown')
    
    Page.first(:name => 'bar').name.should     == 'bar'
    Page.first(:name => 'bar').filename.should == 'bar.markdown'
    Page.first(:name => 'bar').path.should include('foo/bar.markdown')
  end

  it 'supports n levels of sub-directories' do
    create_page 'foo/bar/hello/there/crazy/person-123.markdown'

    Page['foo/bar/hello/there/crazy/person-123'].name.should      == 'person-123'
    Page['foo/bar/hello/there/crazy/person-123'].full_name.should == 'foo/bar/hello/there/crazy/person-123'
    Page['foo/bar/hello/there/crazy/person-123'].parent.should    == 'foo/bar/hello/there/crazy'
    Page['foo/bar/hello/there/crazy/person-123'].filename.should  == 'person-123.markdown'
    Page['foo/bar/hello/there/crazy/person-123'].path.should include('/crazy/person-123.markdown')
    
    Page.first(:name => 'person-123').name.should     == 'person-123'
    Page.first(:name => 'person-123').filename.should == 'person-123.markdown'
    Page.first(:name => 'person-123').path.should include('/crazy/person-123.markdown')
  end

  describe 'Caching' do

    before do
      Page.cache = Hash::Cache.new # Hash that has #get(k) and #set(k,v) methods and #clear
    end

    it 'with the cache enabled, files should only be #read once' do
      create_page 'foo.markdown'
      path = File.join File.dirname(__FILE__), 'pages', 'foo.markdown'

      File.should_receive(:read).with(File.expand_path(path)).once.and_return('') # only once!

      Page[:foo]
      Page[:foo]
    end

    it 'with the cache enabled, Dir[] should only look for files once' do
      create_page 'foo.markdown'
      create_page 'bar.markdown'

      dir = File.dirname(__FILE__)
      Dir.should_receive(:[]).once.and_return(["#{dir}/pages/bar.markdown", "#{dir}/pages/foo.markdown"])
      File.should_receive(:read).twice.and_return('')

      Page.all
      Page.all # calls everyhing again if caching is disabled (Page.cache is nil or false)
    end

    it 'with the cache disabled, Dir[] should only look for files more than once' do
      Page.cache = false

      create_page 'foo.markdown'
      create_page 'bar.markdown'

      dir = File.dirname(__FILE__)
      Dir.should_receive(:[]).twice.and_return(["#{dir}/pages/bar.markdown", "#{dir}/pages/foo.markdown"])
      File.should_receive(:read).exactly(4).times.and_return('')

      Page.all
      Page.all # calls everyhing again if caching is disabled (Page.cache is nil or false)
    end

    it 'should be able to clear the cache' do
      Page.cache.get('all').should be_nil
      Page.all
      Page.cache.get('all').should_not be_nil
      
      Page.cache.clear

      Page.cache.get('all').should be_nil
      Page.all
      Page.cache.get('all').should_not be_nil
    end

    it 'should clear the cache when the Page.dir is changed' do
      Page.cache.get('all').should be_nil
      Page.all
      Page.cache.get('all').should_not be_nil
      
      Page.dir = '/tmp' # different directory

      Page.cache.get('all').should be_nil
      Page.all
      Page.cache.get('all').should_not be_nil
    end

  end

end
