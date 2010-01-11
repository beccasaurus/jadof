shared_examples_for "JADOF Post" do

  describe ':: Behaves like JADOF Post' do

    before do
      @jadof_post_class ||= JADOF::Post # override this in your specs to test a different class!

      @root_page_directory ||= './jadof_spec_pages/'
      @jadof_post_class.dir = File.join(@root_page_directory, 'posts')
      delete_root_page_directory
    end

    after :all do
      delete_root_page_directory
    end

    it 'it should have a date (which is used in to_param)' do
      create_page 'foo.markdown', %{
        ---
        date: 01/31/2010
        ---
        
        hello world
      }, @jadof_post_class.dir

      @jadof_post_class.first.name.should     == 'foo'
      @jadof_post_class.first.to_s.should     == 'foo'
      @jadof_post_class.first.to_param.should == '2010/01/31/foo'
    end

  end

end
