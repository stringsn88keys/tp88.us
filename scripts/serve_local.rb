require 'sinatra'
require 'erb'

helpers do
  def file_description(file)
    if file =~ %r{\Acalculators/}
      match = File.read(file).match(%r{<title>(.*)</title>})
      match ? " - #{match[1]}" : ""
    elsif file =~ %r{\Ascripts/}
      src_file = file.sub(/\.html$/, '')
      if File.exist?(src_file)
        desc = File.read(src_file).each_line.grep(/^##/).first
        desc ? " - #{desc.gsub(/^##/, '').strip}" : ""
      else
        ""
      end
    else
      ""
    end
  end

  def display_filename(file)
    File.basename(file)
  end
end

get '/' do
  resumes = Dir["resumes/*.html"]
  calculators = Dir["calculators/*.html"]
  scripts = Dir["scripts/*.sh.html", "scripts/*.rb.html", "scripts/*.ps1.html", "scripts/*.bat.html"]
  erb :index, locals: { resumes: resumes, calculators: calculators, scripts: scripts }
end

get '/favicon.ico' do
  halt 204
end

get '/*.js' do |file|
  file_path = "#{file}.js"
  if File.exist?(file_path)
    content_type 'application/javascript'
    send_file file_path
  else
    halt 404, "JavaScript file not found"
  end
end

get %r{/(resumes/.*\.html|calculators/.*\.html|scripts/.*\.html)} do
  send_file params['captures'].first
end

__END__

@@index
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Thomas Powell's File Index</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    body {
      background-color: #f4f4f4;
      color: #333333;
    }
    .container {
      background-color: #ffffff;
      border: 1px solid #cccccc;
      border-radius: 8px;
      padding: 20px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    h1 {
      color: #ff4500;
    }
    .list-group-item {
      background-color: #ffefd5;
      color: #333333;
      border: 1px solid #ffdab9;
    }
    .list-group-item:hover {
      background-color: #ffdead;
      color: #000000;
    }
    .footer {
      margin-top: 20px;
      text-align: center;
      font-size: 14px;
    }
    summary {
      font-size: 1.2em;
      font-weight: bold;
      margin-top: 1em;
      margin-bottom: .5em;
      cursor: pointer;
    }
  </style>
</head>
<body>
  <div class="container my-4">
    <h1 class="text-center mb-4">Thomas Powell's File Index</h1>
    <details open>
      <summary>Resumes</summary>
      <div class="list-group mb-3">
        <% resumes.each do |file| %>
          <% title = File.read(file)[/<title>(.*?)<\/title>/im, 1] || File.basename(file) %>
          <a href="/<%= file %>" class="list-group-item list-group-item-action"><%= title %></a>
        <% end %>
      </div>
    </details>
    <details open>
      <summary>Calculators</summary>
      <div class="list-group mb-3">
        <% calculators.each do |file| %>
          <a href="/<%= file %>" class="list-group-item list-group-item-action"><%= display_filename(file) %><%= file_description(file) %></a>
        <% end %>
      </div>
    </details>
    <details open>
      <summary>Scripts</summary>
      <div class="list-group mb-3">
        <% scripts.each do |file| %>
          <a href="/<%= file %>" class="list-group-item list-group-item-action"><%= display_filename(file) %><%= file_description(file) %></a>
        <% end %>
      </div>
    </details>
    <div class="footer">
      <a href="https://thomaspowell.com" target="_blank">Back to Thomas Powell's Website</a>
    </div>
  </div>
</body>
</html>