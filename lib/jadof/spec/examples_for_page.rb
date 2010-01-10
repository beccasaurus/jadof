shared_examples_for "JADOF Page" do

  before do
    @root_page_directory ||= './jadof_spec_pages/'
    JADOF::Page.dir = File.join(@root_page_directory, 'pages')
    delete_root_page_directory
  end

  after :all do
    delete_root_page_directory
  end

  it '#create_page works as expected for creating fake pages for these specs' do
    path = File.join(@root_page_directory, '/pages/foo.markdown')
    File.file?(path).should be_false

    create_page 'foo.markdown'

    File.file?(path).should be_true
    JADOF::Page[:foo].body.should == ''

    create_page 'foo.markdown', %{
      it should fix
        the spaces
      for me
    }

    JADOF::Page[:foo].body.should == "it should fix\n  the spaces\nfor me"
  end

  it 'can set the JADOF::Page.dir to specify the directory to fetch pages from' do
    dir1, dir2 = JADOF::Page.dir, File.join(@root_page_directory, '/more_pages')

    create_page 'foo.markdown', 'hello world', dir1
    create_page 'bar.markdown', 'hello world', dir2

    JADOF::Page[:foo].should_not be_nil
    JADOF::Page[:bar].should     be_nil

    JADOF::Page.dir = dir2

    JADOF::Page[:foo].should     be_nil
    JADOF::Page[:bar].should_not be_nil
  end

  it 'has a filename (the actual filename, without a path)' do
    create_page 'foo.markdown'

    JADOF::Page[:foo].should_not be_nil
    JADOF::Page[:foo].filename.should == 'foo.markdown'
  end

  it 'has a path (the full system path to the file)' do
    create_page 'foo.markdown'

    JADOF::Page[:foo].should_not be_nil
    JADOF::Page[:foo].path.should == File.expand_path(File.join(@root_page_directory, '/pages/foo.markdown'))
  end

  it 'has a name (the name of the file, without extensions)' do
    create_page 'foo.markdown'

    JADOF::Page[:foo].should_not be_nil
    JADOF::Page[:foo].name.should == 'foo'
  end

  it 'has a body (the content of the file)' do
    create_page 'foo.markdown'
    JADOF::Page[:foo].body.should == ''

    create_page 'foo.markdown', %{
      Hello World!
    }

    JADOF::Page[:foo].body.strip.should == 'Hello World!'
  end

  it 'can return all pages' do
    JADOF::Page.count.should      == 0
    JADOF::Page.all.length.should == 0

    create_page 'foo.markdown'
    
    JADOF::Page.count.should      == 1
    JADOF::Page.all.length.should == 1
  end

  it 'can get a page by name' do
    JADOF::Page.get(:foo).should be_nil
    JADOF::Page[:foo].should     be_nil

    create_page 'foo.markdown'

    JADOF::Page.get(:foo).should_not be_nil
    JADOF::Page[:foo].should_not     be_nil
  end

  it 'can add any kind of arbitrary data to a page via YAML' do
    create_page 'foo.markdown'
    JADOF::Page[:foo].foo.should be_nil # JADOF::Page's don't raise NoMethodError's

    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    JADOF::Page[:foo].foo.should == 'bar' # got value from YAML
  end

  it 'can get a page by the value of any arbitrary data (from the YAML)' do
    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    JADOF::Page.first(:foo => 'not bar').should     be_nil
    JADOF::Page.first(:foo => 'bar'    ).should_not be_nil
    JADOF::Page.first(:foo => 'bar'    ).foo.should == 'bar'
  end

  it 'can get a page by *multiple* arbitrary conditions' do
    create_page 'foo.markdown', %{
      ---
      foo: bar
      ---
      Hello World!
    }

    JADOF::Page.where(:foo => 'bar', :name => 'not foo').should be_empty
    JADOF::Page.where(:foo => 'not bar', :name => 'foo').should be_empty
    JADOF::Page.where(:foo => 'bar', :name => 'foo').should_not be_empty
    JADOF::Page.where(:foo => 'bar', :name => 'foo').first.name.should == 'foo'
  end

  it 'supports 1 level of sub-directories' do
    create_page 'hi.markdown'
    JADOF::Page['hi'].parent.should == ''

    create_page 'foo/bar.markdown'

    JADOF::Page['foo/bar'].name.should      == 'bar'
    JADOF::Page['foo/bar'].full_name.should == 'foo/bar'
    JADOF::Page['foo/bar'].parent.should    == 'foo'
    JADOF::Page['foo/bar'].filename.should  == 'bar.markdown'
    JADOF::Page['foo/bar'].path.should include('foo/bar.markdown')
    
    JADOF::Page.first(:name => 'bar').name.should     == 'bar'
    JADOF::Page.first(:name => 'bar').filename.should == 'bar.markdown'
    JADOF::Page.first(:name => 'bar').path.should include('foo/bar.markdown')
  end

  it 'supports n levels of sub-directories' do
    create_page 'foo/bar/hello/there/crazy/person-123.markdown'

    JADOF::Page['foo/bar/hello/there/crazy/person-123'].name.should      == 'person-123'
    JADOF::Page['foo/bar/hello/there/crazy/person-123'].full_name.should == 'foo/bar/hello/there/crazy/person-123'
    JADOF::Page['foo/bar/hello/there/crazy/person-123'].parent.should    == 'foo/bar/hello/there/crazy'
    JADOF::Page['foo/bar/hello/there/crazy/person-123'].filename.should  == 'person-123.markdown'
    JADOF::Page['foo/bar/hello/there/crazy/person-123'].path.should include('/crazy/person-123.markdown')
    
    JADOF::Page.first(:name => 'person-123').name.should     == 'person-123'
    JADOF::Page.first(:name => 'person-123').filename.should == 'person-123.markdown'
    JADOF::Page.first(:name => 'person-123').path.should include('/crazy/person-123.markdown')
  end

  describe 'Caching' do

    before do
      JADOF::Page.cache = Hash::Cache.new # Hash that has #get(k) and #set(k,v) methods and #clear
    end

    it 'with the cache enabled, files should only be #read once' do
      create_page 'foo.markdown'
      path = File.join @root_page_directory, 'pages', 'foo.markdown'

      File.should_receive(:read).with(File.expand_path(path)).once.and_return('') # only once!

      JADOF::Page[:foo]
      JADOF::Page[:foo]
    end

    it 'with the cache enabled, Dir[] should only look for files once' do
      create_page 'foo.markdown'
      create_page 'bar.markdown'

      dir = @root_page_directory
      Dir.should_receive(:[]).once.and_return([File.join(dir, '/pages/bar.markdown'), File.join(dir, '/pages/foo.markdown')])
      File.should_receive(:read).twice.and_return('')

      JADOF::Page.all
      JADOF::Page.all # calls everyhing again if caching is disabled (JADOF::Page.cache is nil or false)
    end

    it 'with the cache disabled, Dir[] should only look for files more than once' do
      JADOF::Page.cache = false

      create_page 'foo.markdown'
      create_page 'bar.markdown'

      dir = @root_page_directory
      Dir.should_receive(:[]).twice.and_return([File.join(dir, '/pages/bar.markdown'), File.join(dir, '/pages/foo.markdown')])
      File.should_receive(:read).exactly(4).times.and_return('')

      JADOF::Page.all
      JADOF::Page.all # calls everyhing again if caching is disabled (JADOF::Page.cache is nil or false)
    end

    it 'should be able to clear the cache' do
      JADOF::Page.cache.get('all').should be_nil
      JADOF::Page.all
      JADOF::Page.cache.get('all').should_not be_nil
      
      JADOF::Page.cache.clear

      JADOF::Page.cache.get('all').should be_nil
      JADOF::Page.all
      JADOF::Page.cache.get('all').should_not be_nil
    end

    it 'should clear the cache when the JADOF::Page.dir is changed' do
      JADOF::Page.cache.get('all').should be_nil
      JADOF::Page.all
      JADOF::Page.cache.get('all').should_not be_nil
      
      JADOF::Page.dir = File.join(@root_page_directory, 'different-directory')

      JADOF::Page.cache.get('all').should be_nil
      JADOF::Page.all
      JADOF::Page.cache.get('all').should_not be_nil
    end

  end

end
