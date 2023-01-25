## create a filename with extended ASCII characters and see if it can be found in the directory listing

# create a file named "ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜ", which is ASCII 128..154
FILENAME=(128..154).to_a.pack('c*').force_encoding(Encoding::IBM437)
UTF_8_FILENAME=FILENAME.encode(Encoding::UTF_8)

Dir.mkdir('tmp') unless Dir.exist?('tmp')
File.open(File.join('tmp', UTF_8_FILENAME), 'wt') do |f|
  f.puts "test"
end


def check_encodings(output)
  if output.include?(UTF_8_FILENAME)
    puts "output matches without forcing encoding"
  end

  puts "Output can be made to match by forcing the following encodings:"
  Encoding.list.each do |encoding|
    if output.force_encoding(encoding).encode(Encoding::UTF_8).include?(UTF_8_FILENAME)
      puts encoding
    end
  rescue
  end
end


command=RUBY_PLATFORM =~ /mingw/ ? 'dir tmp' : 'ls tmp'
puts
puts "%x|#{command}|"
puts "-" * (command.length + 4)
check_encodings(%x|#{command}|)
puts
puts "IO.popen(#{command}).read"
puts "-" * (command.length + 15)
check_encodings(IO.popen(command).read)
