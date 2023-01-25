# create a file named "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ", which is ASCII 128..154
filename=(128..154).to_a.pack('c*').force_encoding(Encoding::IBM437)

Dir.mkdir('tmp') unless Dir.exist?('tmp')
File.open(File.join('tmp', filename.encode(Encoding::UTF_8)), 'wt') do |f|
  f.puts "test"
end

output=%x|dir tmp|


Encoding.list.each do |encoding|
  if output.force_encoding(encoding).encode(Encoding::UTF_8).include?(filename.encode(Encoding::UTF_8))
    puts encoding
  end
rescue
end
