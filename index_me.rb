## Create an index for files

def file_description(file)

  desc = case file
         when /\.rb$/, /\.ps1/
           (File.read(file).each_line.grep(/^##/).first || '').gsub(/^##/,'')
         when /\.htm.*/
           match=File.read(file).match(%r{<title>(.*)</title>})
           if match
             match[1]
           else
             ''
           end
         end
  desc == '' ? '' : " -#{desc}"
end

File.open('index.html', 'wt') do |f|
  f.puts '<html><head><meta charset="utf-8" /><title>TP88.us</title></head><body>'
  f.puts "<ul>"
  Dir["*.rb", "*.ps1", "*.html"].each do |file|
    f.puts %Q|<li><a href="#{file}">#{file}</a>#{file_description(file)}</li>|
  end
  gtag=<<GTAG

<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-Y6GL6564XD"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-Y6GL6564XD');
</script>
GTAG
  f.puts gtag
  f.puts "</body></html>"

end

%x|aws s3 sync . s3://tp88.us|
puts File.read('index.html')
