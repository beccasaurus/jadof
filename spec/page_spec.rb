require File.dirname(__FILE__) + '/spec_helper'

require 'fileutils'

# Helper for creating page files in the specs, at spec/pages/
def create_page filename, body = ''
  FileUtils.mkdir_p Page.dir
  File.open(File.join(Page.dir, filename), 'w'){|f| f << body }
end

# Helper for deleting all pages in spec/pages/
def delete_pages
  Dir[File.join(Page.dir, '**/*')].each do |page|
    FileUtils.rm page
  end
end

describe Page do

  before do
    Page.dir = File.dirname(__FILE__) + '/pages'
    delete_pages
  end

  it 'can set the Page.dir to specify the directory to fetch pages from'

  it 'has a filename (the actual filename, without a path)' do
    create_page 'foo.markdown'

    Page[:foo].should_not be_nil
    Page[:foo].filename.should == 'foo.markdown'
  end

  it 'has a path (the full system path to the file)' do
    create_page 'foo.markdown'

    Page[:foo].should_not be_nil
    Page[:foo].path.should == File.dirname(__FILE__) + '/pages/foo.markdown'
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

  it 'can add any kind of arbitrary data to a page via YAML'

  it 'can get a page by the value of any arbitrary data (from the YAML)'

  it 'supports 1 level of sub-directories'

  it 'supports n levels of sub-directories'

end
