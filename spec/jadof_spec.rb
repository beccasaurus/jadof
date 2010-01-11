require File.dirname(__FILE__) + '/../lib/jadof/spec'

# TODO redo the shared examples so we need to set what class is actually
#      being tested via an instance variable.  this will make it easier 
#      to test that new classes that, for example, in herit from Page, 
#      work properly.

describe JADOF::Page do
  it_should_behave_like "JADOF Page"
end

describe JADOF::Post do
  it_should_behave_like "JADOF Post"
end
