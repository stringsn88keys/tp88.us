require 'csv'
require 'erb'
require 'open-uri'
require 'rouge' # For syntax highlighting
require 'commonmarker' # For GFM rendering

SITE_BASE_URL = 'https://tp88.us'

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

def file_description(file, base_dir)
  desc = case file
         when /\.ps1/
           content = File.read(File.join(base_dir, display_filename(file)))
           # Look for .SYNOPSIS in PowerShell comment-based help
           if content =~ /\.SYNOPSIS\s*\n\s*(.+)/
             $1.strip
           else
             # Fallback to ## style comments
             (content.each_line.grep(/^##/).first || '').gsub(/^##/, '').strip
           end
         when /\.rb/, /\.sh/
           (File.read(File.join(base_dir, display_filename(file))).each_line.grep(/^##/).first || '').gsub(/^##/, '').strip
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

# Return just the description text (no dash prefix) for a script source file
def script_description_text(file)
  case file
  when /\.ps1/
    content = File.read(file)
    if content =~ /\.SYNOPSIS\s*\n\s*(.+)/
      $1.strip
    else
      (content.each_line.grep(/^##/).first || '').gsub(/^##/, '').strip
    end
  when /\.rb/, /\.sh/
    (File.read(file).each_line.grep(/^##/).first || '').gsub(/^##/, '').strip
  else
    ''
  end
end

# Inject SEO <meta> tags into an HTML file's <head> after the viewport meta.
# Skips if a meta[name=description] is already present.
def add_seo_meta(file_path, description:, keywords:, og_title: nil, og_type: 'website', canonical_path: nil)
  content = File.read(file_path)
  return if content.include?('name="description"')

  title_match = content.match(/<title>(.*?)<\/title>/im)
  page_title = og_title || (title_match ? title_match[1].strip : File.basename(file_path))
  canonical_url = canonical_path ? "#{SITE_BASE_URL}/#{canonical_path}" : nil

  seo_block = +''
  seo_block << %(\n    <meta name="description" content="#{description}">)
  seo_block << %(\n    <meta name="keywords" content="#{keywords}">)
  seo_block << %(\n    <meta name="author" content="Thomas Powell">)
  seo_block << %(\n    <meta property="og:title" content="#{page_title}">)
  seo_block << %(\n    <meta property="og:description" content="#{description}">)
  seo_block << %(\n    <meta property="og:type" content="#{og_type}">)
  if canonical_url
    seo_block << %(\n    <meta property="og:url" content="#{canonical_url}">)
    seo_block << %(\n    <link rel="canonical" href="#{canonical_url}">)
  end

  # Insert after the viewport meta tag line
  updated = content.sub(
    /(<meta\s+name="viewport"[^>]*>)/i,
    "\\1#{seo_block}"
  )
  File.write(file_path, updated)
end

# Add Google Analytics to existing HTML files
def add_google_analytics(file_path)
  content = File.read(file_path)
  
  # Check if Google Analytics is already present
  return if content.include?('gtag.js')
  
  # Add Google Analytics before closing </body> tag
  analytics_code = <<~HTML
    
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-QT64MJL0WW"></script>
    <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());

      gtag('config', 'G-QT64MJL0WW');
    </script>
  HTML
  
  # Insert before closing </body> tag
  updated_content = content.gsub(/<\/body>/i, "#{analytics_code}</body>")
  
  # Write the updated content back to the file
  File.write(file_path, updated_content)
end

# Generate syntax-highlighted HTML files for .sh, .rb, and .ps1 files
def generate_highlighted_html(file)
  code = File.read(file)
  lexer = case File.extname(file)
          when '.rb' then Rouge::Lexers::Ruby.new
          when '.sh' then Rouge::Lexers::Shell.new
          when '.ps1' then Rouge::Lexers::Powershell.new
          when '.bat' then Rouge::Lexers::Batchfile.new
          else Rouge::Lexers::PlainText.new
          end
  formatter = Rouge::Formatters::HTML.new
  highlighted_code = formatter.format(lexer.lex(code))

  # Get the raw script filename (without path)
  raw_file = File.basename(file)
  desc_text = script_description_text(file)
  page_title = File.basename(file)
  seo_description = desc_text.empty? ? "#{page_title} - a script by Thomas Powell on tp88.us" : desc_text
  seo_keywords = "#{page_title}, script, Thomas Powell, tp88.us, #{File.extname(file).delete('.')}"
  canonical_path = "#{file}.html"

  File.open("#{file}.html", 'wt') do |f|
    f.puts <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{file}</title>
        <meta name="description" content="#{seo_description}">
        <meta name="keywords" content="#{seo_keywords}">
        <meta name="author" content="Thomas Powell">
        <meta property="og:title" content="#{page_title}">
        <meta property="og:description" content="#{seo_description}">
        <meta property="og:type" content="website">
        <meta property="og:url" content="#{SITE_BASE_URL}/#{canonical_path}">
        <link rel="canonical" href="#{SITE_BASE_URL}/#{canonical_path}">
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
          .raw-link {
            display: inline-block;
            margin-bottom: 15px;
            color: #0066cc;
            text-decoration: none;
            font-size: 14px;
          }
          .raw-link:hover {
            text-decoration: underline;
          }
          .footer {
            margin-top: 20px;
            text-align: center;
            font-size: 14px;
          }
          #{rouge_css} /* Include Rouge's syntax highlighting CSS */
        </style>
      </head>
      <body>
        <div class="container">
          <h1>#{file}</h1>
          <a href="#{raw_file}" class="raw-link">View raw file</a>
          <pre class="highlight"><code>#{highlighted_code}</code></pre>
          <div class="footer">
            <a href="/">Back to Index</a>
          </div>
        </div>

        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-QT64MJL0WW"></script>
        <script>
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());

          gtag('config', 'G-QT64MJL0WW');
        </script>
      </body>
      </html>
    HTML
  end
end

# Render GFM markdown files from blog/ to HTML
def render_blog_markdown(md_file)
  markdown = File.read(md_file)

  # Extract title from first # heading, fall back to filename
  title = markdown[/^\#\s+(.+)/, 1] || File.basename(md_file, '.md')

  # Render GFM to HTML (disable built-in syntax highlighter so we can use Rouge)
  body_html = Commonmarker.to_html(markdown,
    options: { extension: { table: true, autolink: true, strikethrough: true, tasklist: true } },
    plugins: { syntax_highlighter: nil })

  # Post-process fenced code blocks with Rouge syntax highlighting
  body_html.gsub!(%r{<pre lang="([^"]+)"><code>(.*?)</code></pre>}m) do
    lang, code = $1, $2
    # Unescape HTML entities that commonmarker encoded
    code = code.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&amp;', '&').gsub('&quot;', '"')
    lexer = Rouge::Lexer.find_fancy(lang) || Rouge::Lexers::PlainText.new
    formatter = Rouge::Formatters::HTML.new
    highlighted = formatter.format(lexer.lex(code))
    %(<pre class="highlight"><code>#{highlighted}</code></pre>)
  end

  # Extract a plain-text description from the first non-heading paragraph
  first_para = markdown.each_line.map(&:rstrip).drop_while { |l| l.start_with?('#') || l.strip.empty? }.first(3).join(' ').gsub(/[`*_]/, '').squeeze(' ').strip
  blog_description = first_para.length > 20 ? first_para.slice(0, 160).strip : "#{title} - a quick reference guide by Thomas Powell."
  blog_keywords = "#{title}, Thomas Powell, programming, quick reference, #{File.basename(md_file, '.md').tr('_', ' ')}"
  html_file = md_file.sub(/\.md$/, '.html')
  blog_canonical_path = html_file

  File.open(html_file, 'wt') do |f|
    f.puts <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>#{title}</title>
        <meta name="description" content="#{blog_description}">
        <meta name="keywords" content="#{blog_keywords}">
        <meta name="author" content="Thomas Powell">
        <meta property="og:title" content="#{title}">
        <meta property="og:description" content="#{blog_description}">
        <meta property="og:type" content="article">
        <meta property="og:url" content="#{SITE_BASE_URL}/#{blog_canonical_path}">
        <link rel="canonical" href="#{SITE_BASE_URL}/#{blog_canonical_path}">
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
          table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1em;
          }
          th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
          }
          th {
            background-color: #ffefd5;
          }
          .footer {
            margin-top: 20px;
            text-align: center;
            font-size: 14px;
          }
          #{rouge_css}
        </style>
      </head>
      <body>
        <div class="container">
          #{body_html}
          <div class="footer">
            <a href="/">Back to Index</a>
          </div>
        </div>

        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-QT64MJL0WW"></script>
        <script>
          window.dataLayer = window.dataLayer || [];
          function gtag(){dataLayer.push(arguments);}
          gtag('js', new Date());

          gtag('config', 'G-QT64MJL0WW');
        </script>
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

# Generate books visualization HTML files
system('ruby', File.join(__dir__, 'visualize_books.rb'), '-o', 'books_all.html')
system('ruby', File.join(__dir__, 'visualize_books.rb'), '--completed-only', '-o', 'books_completed.html')

# Refresh coffee.csv from Google Sheets
coffee_csv_url = 'https://docs.google.com/spreadsheets/d/1FyNziCWhpu5cp_qf-oFrHPgAByhFfXiAvGp9XL0_42Q/export?format=csv'
begin
  csv_data = URI.open(coffee_csv_url).read
  # Strip currency symbols from Cost column so values parse as numbers
  table = CSV.parse(csv_data, headers: true)
  cost_header = table.headers.find { |h| h.strip.downcase == 'cost' }
  if cost_header
    table.each { |row| row[cost_header] = row[cost_header].to_s.gsub(/[^0-9.]/, '') }
  end
  File.write(File.join(__dir__, 'data', 'coffee.csv'), table.to_csv)
  puts "Refreshed data/coffee.csv from Google Sheets"
rescue => e
  puts "Warning: Could not refresh coffee.csv: #{e.message}"
end

# Generate coffee visualization HTML file
system('ruby', File.join(__dir__, 'visualize_coffee.rb'), '-o', 'coffee.html')

# Add Google Analytics and SEO meta to books HTML files
Dir["books_*.html"].each do |file|
  add_google_analytics(file)
  add_seo_meta(file,
    description: "Thomas Powell's reading visualization — interactive chart of books read, #{File.basename(file, '.html').include?('completed') ? 'completed books only' : 'all books including in-progress'}.",
    keywords: "Thomas Powell, books, reading list, book visualization, Goodreads, reading tracker",
    canonical_path: file
  )
end

# Add Google Analytics and SEO meta to coffee HTML file
add_google_analytics('coffee.html')
add_seo_meta('coffee.html',
  description: "Thomas Powell's coffee consumption visualization — an interactive chart tracking coffee drinks over time.",
  keywords: "Thomas Powell, coffee, coffee tracker, visualization, coffee consumption",
  canonical_path: 'coffee.html'
)

# Add Google Analytics and SEO meta to calculator HTML files (after ERB rendering)
Dir["calculators/*.html"].each do |file|
  add_google_analytics(file)
  add_seo_meta(file,
    description: (File.read(file).match(/<title>(.*?)<\/title>/im)&.[](1)&.strip || File.basename(file)) + " — an interactive calculator by Thomas Powell.",
    keywords: "calculator, #{File.basename(file, '.html').tr('-_', ' ')}, Thomas Powell, tp88.us",
    canonical_path: file
  )
end

# Render GFM markdown files from blog/ to HTML
Dir["blog/*.md"].each { |md_file| render_blog_markdown(md_file) }

# Add Google Analytics to blog HTML files
Dir["blog/*.html"].each do |file|
  add_google_analytics(file)
end

# Add Google Analytics to resumes HTML files
Dir["resumes/*.html"].each do |file|
  add_google_analytics(file)
end

File.open('index.html', 'wt') do |f|
  f.puts <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Thomas Powell's File Index</title>
      <meta name="description" content="Thomas Powell's personal site - scripts, calculators, resumes, blog posts, and book and coffee visualizations.">
      <meta name="keywords" content="Thomas Powell, scripts, calculators, resumes, Ruby, PowerShell, shell scripts, AWS, DevOps, blog, books, coffee">
      <meta name="author" content="Thomas Powell">
      <meta property="og:title" content="Thomas Powell's File Index">
      <meta property="og:description" content="Thomas Powell's personal site - scripts, calculators, resumes, blog posts, and visualizations.">
      <meta property="og:type" content="website">
      <meta property="og:url" content="#{SITE_BASE_URL}/">
      <link rel="canonical" href="#{SITE_BASE_URL}/">
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
      <script>
        document.addEventListener('DOMContentLoaded', function() {
          // Restore saved states
          document.querySelectorAll('details[id]').forEach(function(details) {
            var saved = localStorage.getItem('details-' + details.id);
            if (saved !== null) {
              details.open = saved === 'true';
            }
          });
          // Save state on toggle
          document.querySelectorAll('details[id]').forEach(function(details) {
            details.addEventListener('toggle', function() {
              localStorage.setItem('details-' + details.id, details.open);
            });
          });
        });
      </script>
    </head>
    <body>
      <div class="container my-4">
        <h1 class="text-center mb-4">Thomas Powell's File Index</h1>
        <details id="resumes" open>
          <summary>Resumes</summary>
          <div class="list-group mb-3">
  HTML

  Dir["resumes/*.html"].each do |file|
    title = File.read(file)[/<title>(.*?)<\/title>/im, 1] || File.basename(file)
    f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{title}</a>|
  end

  f.puts <<~HTML
          </div>
        </details>
        <details id="blog" open>
          <summary>Blog</summary>
          <div class="list-group mb-3">
  HTML

  Dir["blog/*.html"].each do |file|
    title = File.read(file)[/<title>(.*?)<\/title>/im, 1] || File.basename(file)
    f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{title}</a>|
  end

  f.puts <<~HTML
          </div>
        </details>
        <details id="books" open>
          <summary>Books</summary>
          <div class="list-group mb-3">
            <a href="books_all.html" class="list-group-item list-group-item-action">Reading Visualization - All Books</a>
            <a href="books_completed.html" class="list-group-item list-group-item-action">Reading Visualization - Completed Only</a>
          </div>
        </details>
        <details id="coffee" open>
          <summary>Coffee</summary>
          <div class="list-group mb-3">
            <a href="coffee.html" class="list-group-item list-group-item-action">Coffee Consumption Visualization</a>
          </div>
        </details>
        <details id="calculators" open>
          <summary>Calculators</summary>
          <div class="list-group mb-3">
  HTML

  Dir["calculators/*.html"].each do |file|
    f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{File.basename(file)}#{file_description(file, "scripts")}</a>|
  end

  f.puts <<~HTML
          </div>
        </details>
        <details id="scripts" open>
          <summary>Scripts</summary>
  HTML

  file_types = {
    '🐚 Shell Scripts (.sh)' => Dir["scripts/*.sh.html"],
    '💎 Ruby Scripts (.rb)' => Dir["scripts/*.rb.html"],
    '⚡ PowerShell Scripts (.ps1)' => Dir["scripts/*.ps1.html"],
    '🪟 Batch Files (.bat)' => Dir["scripts/*.bat.html"]
  }

  file_types.each do |label, files|
    next if files.empty?
    detail_id = label.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+$/, '')
    f.puts <<~HTML
          <details id="#{detail_id}" open>
            <summary style="font-size: 1em; margin-left: 1em;">#{label}</summary>
            <div class="list-group mb-3" style="margin-left: 1em;">
    HTML
    files.each do |file|
      f.puts %Q|<a href="#{file}" class="list-group-item list-group-item-action">#{display_filename(file)}#{file_description(file, "scripts")}</a>|
    end
    f.puts <<~HTML
            </div>
          </details>
    HTML
  end

  f.puts <<~HTML
        </details>
        <div class="footer">
          <a href="https://thomaspowell.com" target="_blank">Back to Thomas Powell's Website</a>
        </div>
      </div>

      <!-- Google tag (gtag.js) -->
      <script async src="https://www.googletagmanager.com/gtag/js?id=G-QT64MJL0WW"></script>
      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());

        gtag('config', 'G-QT64MJL0WW');
      </script>
    </body>
    </html>
  HTML
end

# Generate robots.txt
File.write('robots.txt', <<~ROBOTS)
  User-agent: *
  Allow: /

  Sitemap: #{SITE_BASE_URL}/sitemap.xml
ROBOTS

# Generate sitemap.xml
sitemap_urls = []

# Root index
sitemap_urls << { loc: "#{SITE_BASE_URL}/", priority: '1.0', changefreq: 'weekly' }

# Resumes
Dir["resumes/*.html"].each do |f|
  sitemap_urls << { loc: "#{SITE_BASE_URL}/#{f}", priority: '0.8', changefreq: 'monthly' }
end

# Blog
Dir["blog/*.html"].each do |f|
  sitemap_urls << { loc: "#{SITE_BASE_URL}/#{f}", priority: '0.8', changefreq: 'monthly' }
end

# Books
%w[books_all.html books_completed.html].each do |f|
  sitemap_urls << { loc: "#{SITE_BASE_URL}/#{f}", priority: '0.6', changefreq: 'weekly' }
end

# Coffee
sitemap_urls << { loc: "#{SITE_BASE_URL}/coffee.html", priority: '0.5', changefreq: 'weekly' }

# Calculators
Dir["calculators/*.html"].each do |f|
  sitemap_urls << { loc: "#{SITE_BASE_URL}/#{f}", priority: '0.7', changefreq: 'monthly' }
end

# Scripts
Dir["scripts/*.sh.html", "scripts/*.rb.html", "scripts/*.ps1.html", "scripts/*.bat.html"].each do |f|
  sitemap_urls << { loc: "#{SITE_BASE_URL}/#{f}", priority: '0.5', changefreq: 'monthly' }
end

today = Time.now.strftime('%Y-%m-%d')
File.open('sitemap.xml', 'wt') do |f|
  f.puts '<?xml version="1.0" encoding="UTF-8"?>'
  f.puts '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  sitemap_urls.each do |url|
    f.puts '  <url>'
    f.puts "    <loc>#{url[:loc]}</loc>"
    f.puts "    <lastmod>#{today}</lastmod>"
    f.puts "    <changefreq>#{url[:changefreq]}</changefreq>"
    f.puts "    <priority>#{url[:priority]}</priority>"
    f.puts '  </url>'
  end
  f.puts '</urlset>'
end

puts "Generated robots.txt and sitemap.xml (#{sitemap_urls.length} URLs)"

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