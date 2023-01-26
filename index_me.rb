## Create an index for files

def file_description(file)
  desc = (File.read(file).each_line.grep(/^##/).first || '').gsub(/^##/,'')
  desc == '' ? '' : " -#{desc}"
end

File.open('index.html', 'wt') do |f|
  f.puts "<html><head><title>TP88.us</title></head><body>"
  f.puts "<ul>"
  Dir["*.rb", "*.ps1"].each do |file|
    f.puts %Q|<li><a href="#{file}">#{file}</a>#{file_description(file)}</li>|
  end
  f.puts "</body></html>"
end

%x|aws s3 sync . s3://tp88.us|
puts File.read('index.html')
