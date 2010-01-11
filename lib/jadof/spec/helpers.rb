# Helper for creating page files in the specs, at spec/pages/
#
#   create_page 'foo.markdown'
#
#   create_page 'foo.markdown', %{
#     This is the body
#     of the page that will
#     be created.
#   }
#
#   create_page 'foo.markdown', 'body',  './directory/to/create/page/in/'
#
def create_page filename, body = '', page_dir = @jadof_page_class.dir
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

# Deletes the root directory that we create pages in
def delete_root_page_directory
  FileUtils.rm_rf @root_page_directory
end
