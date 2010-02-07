%w( rubygems rack/test ).each {|lib| require lib }

require File.dirname(__FILE__) + '/../examples/sinatra-app'

describe 'Example Sinatra app' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    # because we keep resetting Page.dir in the specs, 
    # we need to point it to the right dir for these
    Page.dir = File.dirname(__FILE__) + '/../examples/pages'
  end

  it 'home page should work' do
    get '/'
    last_response.status.should == 200
    last_response.body.should include('Our Pages')
    last_response.body.should include("<a href='/foo'>")
  end

  it 'example other page should work' do
    get '/foo'
    last_response.status.should == 200
    last_response.body.should include('<em>Hello</em> <strong>from</strong> <code>foo</code>')
  end

end
