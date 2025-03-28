require 'sinatra'
require 'erb'

# Root route to list all .erb files with links
get '/' do
  erb_files = Dir["*.html.erb"]
  erb :index, locals: { erb_files: erb_files }
end


# Route to handle favicon.ico requests
get '/favicon.ico' do
  # Return a blank response or serve an actual favicon file if available
  halt 204 # No Content
end

# Route to serve .js files as-is
get '/*.js' do |file|
  file_path = "#{file}.js"
  if File.exist?(file_path)
    content_type 'application/javascript'
    send_file file_path
  else
    halt 404, "JavaScript file not found"
  end
end

# Dynamic route to render individual .erb files
get '/:file' do
  file_name = params[:file]
  erb_content = File.read("#{file_name}.erb")
  ERB.new(erb_content).result(binding)
end

__END__

@@index
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ERB File List</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
  <div class="container my-4">
    <h1 class="text-center">Available ERB Files</h1>
    <ul class="list-group">
      <% erb_files.each do |file| %>
        <li class="list-group-item">
          <a href="/<%= File.basename(file, '.erb') %>"><%= file %></a>
        </li>
      <% end %>
    </ul>
  </div>
</body>
</html>