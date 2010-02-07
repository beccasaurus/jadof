require File.dirname(__FILE__) + '/../lib/jadof'
include JADOF

%w( rubygems sinatra haml maruku erb ).each {|lib| require lib }

set :root, File.dirname(__FILE__)

get '/' do
  @page = Page.get 'index'
  haml :page
end

get '/:name' do |name|
  @page = Page.get name
  haml :page
end

__END__

@@ layout
!!! XML
!!!
%html
  %head
    %title My Site
  %body
    #content= yield

@@ page

- if @page

  .page
    %h2=   @page.name
    .body= @page.to_html

- else
  %p Page not found.
