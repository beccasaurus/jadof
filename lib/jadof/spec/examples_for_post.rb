shared_examples_for "JADOF Post" do

  before do
    @root_page_directory ||= './jadof_spec_pages/'
    JADOF::Post.dir = File.join(@root_page_directory, 'posts')
    delete_root_page_directory
  end

  after :all do
    delete_root_page_directory
  end

  it 'should behave like JADOF Page (need to add this in here!)'

  it 'it should have a date (which is used in to_param)' do
    create_page 'foo.markdown', %{
      ---
      date: 01/31/2010
      ---
      
      hello world
    }, JADOF::Post.dir

    JADOF::Post.first.name.should     == 'foo'
    JADOF::Post.first.to_s.should     == 'foo'
    JADOF::Post.first.to_param.should == '2010/01/31/foo'
  end

end
