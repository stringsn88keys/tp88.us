require 'erb'
require 'rouge' # For syntax highlighting

# Generate the CSS for Rouge's syntax highlighting
def rouge_css
  theme = Rouge::Themes::ThankfulEyes.new # You can choose a different theme if you prefer
  theme.render # Generate the CSS for the theme
end

def display_filename(file)
  case file
  when /\.rb/, /\.sh/, /\.ps1/
    File.basename(file, '.*').sub(/\.html$/, '')
  else
    File.basename(file, '.*')
  end
end

def file_description(file)
  desc = case file
         when /\.rb/, /\.ps1/, /\.sh/
           (File.read(display_filename(file)).each_line.grep(/^##/).first || '').gsub(/^##/, '')
         when /\.htm.*/
           match = File.read(file).match(%r{<title>(.*)</title>})
           if match
             match[1]
           else
             ''
           end
         end
  desc == '' ? '' : " - #{desc}"
end

# Generate syntax-highlighted HTML files for .sh, .rb, and .ps1 files
def generate_highlighted_html(file)
  code = File.read(file)
  lexer = case File.extname(file)
          when '.rb' then Rouge::Lexers::Ruby.new
          when '.sh' then Rouge::Lexers::Shell.new
          when '.ps1' then Rouge::Lexers::Powershell.new
          when '.bat' then Rouge::Lexers::Batch.new
          else Rouge::Lexers::PlainText.new
          end
  formatter = Rouge::Formatters::HTML.new
  highlighted_code = formatter.format(lexer.lex(code))

  File.open("#{file}.html", 'wt') do |f|
    f.puts <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{file}</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
          body {
            background-color: #f4f4f4;
            color: #333333;
            font-family: Arial, sans-serif;
          }
          .container {
            margin-top: 20px;
            background-color: #ffffff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
          }
          pre {
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
          }
          h1 {
            color: #ff4500;
          }
          #{rouge_css} /* Include Rouge's syntax highlighting CSS */
        </style>
      </head>
      <body>
        <div class="container">
          <h1>#{file}</h1>
          <pre class="highlight"><code>#{highlighted_code}</code></pre>
        </div>
      </body>
      </html>
    HTML
  end
end

# Render .erb files to non-.erb versions
Dir["calculators/*.html.erb"].each do |erb_file|
  rendered_file = erb_file.sub(/\.erb$/, '') # Remove .erb extension
  erb_content = File.read(erb_file)
  result = ERB.new(erb_content).result(binding) # Render the ERB file
  File.write(rendered_file, result) # Write the rendered content to the new file
end

# Generate syntax-highlighted HTML files for .sh, .rb, and .ps1 files
Dir["scripts/*.sh", "scripts/*.rb", "scripts/*.ps1", "scripts/*.bat"].each do |file|
  generate_highlighted_html(file)
end

File.open('index.html', 'wt') do |f|
  f.puts <<~HTML
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
      </style>
    </head>
    <body>
      <div class="container my-4">
        <h1 class="text-center mb-4">Thomas Powell's File Index</h1>
        <div class="list-group">
  HTML

  Dir["*.sh.html", "*.rb.html", "*.ps1.html", "*.html"].each do |file|
    f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{display_filename(file)}#{file_description(file)}</a>|
  end

  f.puts <<~HTML
        </div>
        <div class="footer">
          <a href="https://thomaspowell.com" target="_blank">Back to Thomas Powell's Website</a>
        </div>
      </div>

      <!-- Google tag (gtag.js) -->
      <script async src="https://www.googletagmanager.com/gtag/js?id=G-Y6GL6564XD"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'G-Y6GL6564XD');
      </script>
    </body>
    </html>
  HTML
end

# Sync files to S3
%x|aws s3 sync . s3://tp88.us|

# Retrieve the CloudFront distribution ID for tp88.us
distribution_id = %x|aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[?@=='tp88.us']].Id" --output text|.strip

if ENV['DO_INVALIDATION']
  if distribution_id.empty?
    puts "Error: Could not find CloudFront distribution for tp88.us"
  else
    # Invalidate the CloudFront distribution
    puts "Invalidating CloudFront distribution: #{distribution_id}"
    %x|aws cloudfront create-invalidation --distribution-id #{distribution_id} --paths "/*"|
  end
end

puts File.read('index.html')