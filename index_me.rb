## Create an index for files
require 'erb'

def file_description(file)
  desc = case file
         when /\.rb$/, /\.ps1/
           (File.read(file).each_line.grep(/^##/).first || '').gsub(/^##/, '')
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

# Render .erb files to non-.erb versions
Dir["*.html.erb"].each do |erb_file|
  rendered_file = erb_file.sub(/\.erb$/, '') # Remove .erb extension
  erb_content = File.read(erb_file)
  result = ERB.new(erb_content).result(binding) # Render the ERB file
  File.write(rendered_file, result) # Write the rendered content to the new file
end

File.open('index.html', 'wt') do |f|
  f.puts <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>TP88.us</title>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
      <style>
        body {
          background-color: #f4f4f4; /* Light gray from the image */
          color: #333333; /* Dark gray for text */
        }
        .container {
          background-color: #ffffff; /* White background for the container */
          border: 1px solid #cccccc; /* Light gray border */
          border-radius: 8px;
          padding: 20px;
          box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
          color: #ff4500; /* Orange-red for the title */
        }
        .list-group-item {
          background-color: #ffefd5; /* Pale goldenrod for list items */
          color: #333333;
          border: 1px solid #ffdab9; /* Peach puff for borders */
        }
        .list-group-item:hover {
          background-color: #ffdead; /* Navajo white for hover effect */
          color: #000000; /* Black text on hover */
        }
      </style>
    </head>
    <body>
      <div class="container my-4">
        <h1 class="text-center mb-4">File Index</h1>
        <div class="list-group">
  HTML

  Dir["*.sh", "*.rb", "*.ps1", "*.html"].each do |file|
    f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{file}#{file_description(file)}</a>|
  end

  f.puts <<~HTML
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

if distribution_id.empty?
  puts "Error: Could not find CloudFront distribution for tp88.us"
else
  # Invalidate the CloudFront distribution
  puts "Invalidating CloudFront distribution: #{distribution_id}"
  %x|aws cloudfront create-invalidation --distribution-id #{distribution_id} --paths "/*"|
end

puts File.read('index.html')