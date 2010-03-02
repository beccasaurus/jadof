shared_examples_for "JADOF Page" do

  describe ':: Behaves like JADOF Page' do

    before do
      @jadof_page_class ||= JADOF::Page # override this in your specs to test a different class!

      @root_page_directory ||= './jadof_spec_pages/'
      @jadof_page_class.dir = File.join(@root_page_directory, 'pages')
      delete_root_page_directory
    end

    after :all do
      delete_root_page_directory
    end

    it '#create_page works as expected for creating fake pages for these specs' do
      path = File.join(@jadof_page_class.dir, '/foo.markdown')
      File.file?(path).should be_false

      create_page 'foo.markdown'

      File.file?(path).should be_true
      @jadof_page_class[:foo].body.should == ''

      create_page 'foo.markdown', %{
        it should fix
          the spaces
        for me
      }

      @jadof_page_class[:foo].body.should == "it should fix\n  the spaces\nfor me"
    end

    it 'can set the @jadof_page_class.dir to specify the directory to fetch pages from' do
      dir1, dir2 = @jadof_page_class.dir, File.join(@root_page_directory, '/more_pages')

      create_page 'foo.markdown', 'hello world', dir1
      create_page 'bar.markdown', 'hello world', dir2

      @jadof_page_class[:foo].should_not be_nil
      @jadof_page_class[:bar].should     be_nil

      @jadof_page_class.dir = dir2

      @jadof_page_class[:foo].should     be_nil
      @jadof_page_class[:bar].should_not be_nil
    end

    it 'has a filename (the actual filename, without a path)' do
      create_page 'foo.markdown'

      @jadof_page_class[:foo].should_not be_nil
      @jadof_page_class[:foo].filename.should == 'foo.markdown'
    end

    it 'can easily get file extensions' do
      create_page '123'
      create_page 'foo.markdown'
      create_page 'bar.markdown.haml'
      create_page 'abc.markdown.haml.something'

      @jadof_page_class['123'].extensions.should == %w( )
      @jadof_page_class[:foo ].extensions.should == %w( markdown )
      @jadof_page_class[:bar ].extensions.should == %w( markdown haml )
      @jadof_page_class[:abc ].extensions.should == %w( markdown haml something )
    end

    it 'has a path (the full system path to the file)' do
      create_page 'foo.markdown'

      @jadof_page_class[:foo].should_not be_nil
      @jadof_page_class[:foo].path.should == File.expand_path(File.join(@jadof_page_class.dir, '/foo.markdown'))
    end

    it 'has a name (the name of the file, without extensions)' do
      create_page 'foo.markdown'

      @jadof_page_class[:foo].should_not be_nil
      @jadof_page_class[:foo].name.should == 'foo'
    end

    it 'has a body (the content of the file)' do
      create_page 'foo.markdown'
      @jadof_page_class[:foo].body.should == ''

      create_page 'foo.markdown', %{
        Hello World!
      }

      @jadof_page_class[:foo].body.strip.should == 'Hello World!'
    end

    it 'can return all pages' do
      @jadof_page_class.count.should      == 0
      @jadof_page_class.all.length.should == 0

      create_page 'foo.markdown'
      
      @jadof_page_class.count.should      == 1
      @jadof_page_class.all.length.should == 1
    end

    it 'can return #first and #last page' do
      create_page 'foo.markdown'
      create_page 'bar.markdown'
      
      @jadof_page_class.first.should == @jadof_page_class.all.first
      @jadof_page_class.last.should  == @jadof_page_class.all.last

      @jadof_page_class.first.should_not == @jadof_page_class.last
    end

    it 'can get a page by name' do
      @jadof_page_class.get(:foo).should be_nil
      @jadof_page_class[:foo].should     be_nil

      create_page 'foo.markdown'

      @jadof_page_class.get(:foo).should_not be_nil
      @jadof_page_class[:foo].should_not     be_nil
    end

    it 'supports 1 level of sub-directories' do
      create_page 'hi.markdown'
      @jadof_page_class['hi'].parent.should == ''

      create_page 'foo/bar.markdown'

      @jadof_page_class['foo/bar'].name.should      == 'bar'
      @jadof_page_class['foo/bar'].full_name.should == 'foo/bar'
      @jadof_page_class['foo/bar'].parent.should    == 'foo'
      @jadof_page_class['foo/bar'].filename.should  == 'bar.markdown'
      @jadof_page_class['foo/bar'].path.should include('foo/bar.markdown')
      
      @jadof_page_class.first(:name => 'bar').name.should     == 'bar'
      @jadof_page_class.first(:name => 'bar').filename.should == 'bar.markdown'
      @jadof_page_class.first(:name => 'bar').path.should include('foo/bar.markdown')
    end

    it 'supports n levels of sub-directories' do
      create_page 'foo/bar/hello/there/crazy/person-123.markdown'

      @jadof_page_class['foo/bar/hello/there/crazy/person-123'].name.should      == 'person-123'
      @jadof_page_class['foo/bar/hello/there/crazy/person-123'].full_name.should == 'foo/bar/hello/there/crazy/person-123'
      @jadof_page_class['foo/bar/hello/there/crazy/person-123'].parent.should    == 'foo/bar/hello/there/crazy'
      @jadof_page_class['foo/bar/hello/there/crazy/person-123'].filename.should  == 'person-123.markdown'
      @jadof_page_class['foo/bar/hello/there/crazy/person-123'].path.should include('/crazy/person-123.markdown')
      
      @jadof_page_class.first(:name => 'person-123').name.should     == 'person-123'
      @jadof_page_class.first(:name => 'person-123').filename.should == 'person-123.markdown'
      @jadof_page_class.first(:name => 'person-123').path.should include('/crazy/person-123.markdown')
    end

    it 'implements #to_s (defaults to #full_name)' do
      create_page 'hi.markdown'
      create_page 'foo/bar/hello/there/crazy/person-123.markdown'
      
      @jadof_page_class[:hi].to_s.should == 'hi'
      @jadof_page_class.first(:name => 'person-123').to_s.should == 'foo/bar/hello/there/crazy/person-123'
    end

    it 'implements #to_param (defaults to #full_name)' do
      create_page 'hi.markdown'
      create_page 'foo/bar/hello/there/crazy/person-123.markdown'

      @jadof_page_class[:hi].to_param.should == 'hi'
      @jadof_page_class.first(:name => 'person-123').to_param.should == 'foo/bar/hello/there/crazy/person-123'
    end

    describe ':: YAML header' do

      it 'can add any kind of arbitrary data to a page via YAML' do
        create_page 'foo.markdown'
        @jadof_page_class[:foo].foo.should be_nil # @jadof_page_class's don't raise NoMethodError's

        create_page 'foo.markdown', %{
          ---
          foo: bar
          ---
          Hello World!
        }

        @jadof_page_class[:foo].foo.should == 'bar' # got value from YAML
      end

      it 'can get a page by the value of any arbitrary data (from the YAML)' do
        create_page 'foo.markdown', %{
          ---
          foo: bar
          ---
          Hello World!
        }

        @jadof_page_class.first(:foo => 'not bar').should     be_nil
        @jadof_page_class.first(:foo => 'bar'    ).should_not be_nil
        @jadof_page_class.first(:foo => 'bar'    ).foo.should == 'bar'
      end

      it 'can get a page by *multiple* arbitrary conditions via #all or #where' do
        create_page 'foo.markdown', %{
          ---
          foo: bar
          ---
          Hello World!
        }

        @jadof_page_class.where(:foo => 'bar', :name => 'not foo').should be_empty
        @jadof_page_class.where(:foo => 'not bar', :name => 'foo').should be_empty
        @jadof_page_class.where(:foo => 'bar', :name => 'foo').should_not be_empty
        @jadof_page_class.where(:foo => 'bar', :name => 'foo').first.name.should == 'foo'

        @jadof_page_class.all(:foo => 'bar', :name => 'not foo').should be_empty
        @jadof_page_class.all(:foo => 'not bar', :name => 'foo').should be_empty
        @jadof_page_class.all(:foo => 'bar', :name => 'foo').should_not be_empty
        @jadof_page_class.all(:foo => 'bar', :name => 'foo').first.name.should == 'foo'
      end

    end

    describe ':: Rendering' do

      before do
        @jadof_page_class.formatters = {}
      end

      it 'should render plain text if formatter not found for file extension' do
        create_page 'foo.markdown', %{
          **Hello World!**
        }

        @jadof_page_class[:foo].render.should == '**Hello World!**'
        @jadof_page_class[:foo].to_html.should == '**Hello World!**'
      end
      
      it 'should render using formatter if found for file extension' do
        @jadof_page_class.formatters['markdown'] = lambda {|text| Maruku.new(text).to_html }

        create_page 'foo.markdown', %{
          **Hello World!**
        }

        @jadof_page_class[:foo].render.should == '<p><strong>Hello World!</strong></p>'
        @jadof_page_class[:foo].to_html.should == '<p><strong>Hello World!</strong></p>'
      end

      it 'formatters have access to the page' do
        @jadof_page_class.formatters['something'] = lambda do |text, page|
          text.gsub('FILENAME', page.filename)
        end

        create_page 'foo.something', %{
          Hello from FILENAME
        }

        @jadof_page_class[:foo].body.should   == 'Hello from FILENAME'
        @jadof_page_class[:foo].render.should == 'Hello from foo.something'
      end

      it 'formatters can be a class' do
        class UpcaseFormatter
          def self.call text
            text.upcase
          end
        end

        class FilenameFormatter
          def self.call text, page
            text.sub "FILENAME", page.filename
          end
        end

        @jadof_page_class.formatters['upcase']   = UpcaseFormatter
        @jadof_page_class.formatters['filename'] = FilenameFormatter

        create_page 'foo.upcase', %{
          Hello from FILENAME
        }
        create_page 'bar.filename', %{
          Hello from FILENAME
        }

        @jadof_page_class[:foo].render.should == 'HELLO FROM FILENAME'
        @jadof_page_class[:bar].render.should == 'Hello from bar.filename'
      end

      it 'should support multiple file extensions, eg. foo.markdown.erb (erb renders first, then markdown)' do
        @jadof_page_class.formatters['markdown'] = lambda {|text| Maruku.new(text).to_html }

        create_page 'foo.markdown.erb', %{
          <%= '*' * 2 %>Hello World!<%= '*' * 2 %>
        }

        @jadof_page_class[:foo].to_html.should == 
          '<p>&lt;%= &#8217;<em>&#8217;</em> 2 %&gt;Hello World!&lt;%= &#8217;<em>&#8217;</em> 2 %&gt;</p>'


        @jadof_page_class.formatters['erb'] = lambda {|text| ERB.new(text).result }
        @jadof_page_class[:foo].to_html.should == '<p><strong>Hello World!</strong></p>'
      end

      it 'should have markdown and erb out of the box' do
        create_page 'foo.markdown.erb', %{
          <%= '*' * 2 %>Hello World!<%= '*' * 2 %>
        }

        @jadof_page_class.formatters = @jadof_page_class::DEFAULT_FORMATTERS
        @jadof_page_class[:foo].to_html.should == '<p><strong>Hello World!</strong></p>'
      end

      it 'should have haml out of the box' do
        create_page 'foo.haml', "#hola= 'Hello World'"
        @jadof_page_class.formatters = @jadof_page_class::DEFAULT_FORMATTERS
        @jadof_page_class[:foo].to_html.should == "<div id='hola'>Hello World</div>\n"
      end
      
      it 'should have textile out of the box' do
        create_page 'foo.textile', 'h1. Hello World!'
        @jadof_page_class.formatters = @jadof_page_class::DEFAULT_FORMATTERS
        @jadof_page_class[:foo].to_html.should == '<h1>Hello World!</h1>'
      end
      
    end

    describe ':: Caching' do

      before do
        @jadof_page_class.cache = Hash::Cache.new # Hash that has #get(k) and #set(k,v) methods and #clear
      end

      it 'with the cache enabled, files should only be #read once' do
        create_page 'foo.markdown'
        path = File.join @jadof_page_class.dir, 'foo.markdown'

        File.should_receive(:read).with(File.expand_path(path)).once.and_return('') # only once!

        @jadof_page_class[:foo]
        @jadof_page_class[:foo]
      end

      it 'with the cache enabled, Dir[] should only look for files once' do
        create_page 'foo.markdown'
        create_page 'bar.markdown'

        dir = @root_page_directory
        Dir.should_receive(:[]).once.and_return([File.join(dir, '/pages/bar.markdown'), File.join(dir, '/pages/foo.markdown')])
        File.should_receive(:read).twice.and_return('')

        @jadof_page_class.all
        @jadof_page_class.all # calls everyhing again if caching is disabled (@jadof_page_class.cache is nil or false)
      end

      it 'with the cache disabled, Dir[] should only look for files more than once' do
        @jadof_page_class.cache = false

        create_page 'foo.markdown'
        create_page 'bar.markdown'

        dir = @root_page_directory
        Dir.should_receive(:[]).twice.and_return([File.join(dir, '/pages/bar.markdown'), File.join(dir, '/pages/foo.markdown')])
        File.should_receive(:read).exactly(4).times.and_return('')

        @jadof_page_class.all
        @jadof_page_class.all # calls everyhing again if caching is disabled (@jadof_page_class.cache is nil or false)
      end

      it 'should be able to clear the cache' do
        @jadof_page_class.cache.get('all').should be_nil
        @jadof_page_class.all
        @jadof_page_class.cache.get('all').should_not be_nil
        
        @jadof_page_class.cache.clear

        @jadof_page_class.cache.get('all').should be_nil
        @jadof_page_class.all
        @jadof_page_class.cache.get('all').should_not be_nil
      end

      it 'should clear the cache when the @jadof_page_class.dir is changed' do
        @jadof_page_class.cache.get('all').should be_nil
        @jadof_page_class.all
        @jadof_page_class.cache.get('all').should_not be_nil
        
        @jadof_page_class.dir = File.join(@root_page_directory, 'different-directory')

        @jadof_page_class.cache.get('all').should be_nil
        @jadof_page_class.all
        @jadof_page_class.cache.get('all').should_not be_nil
      end

    end

  end

end
