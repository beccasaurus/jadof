# this example is from http://remi.org/2010/02/24/jadof
%w( sinatra jadof ).each {|lib| require lib }

get '/' do
  @pages = JADOF::Page.all
  haml :index
end

get '/*' do
  JADOF::Page.get(params[:splat]).to_html
end

__END__

@@ index
%h1 Pages
%ul
  - for page in @pages
    %li
      %a{ :href => "/#{ page.to_param }" }= page.name
