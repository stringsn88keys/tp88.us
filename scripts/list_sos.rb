## List all .so shared library files found in Ruby's load path ($LOAD_PATH)
$:.each do |path|
  Dir[File.join(path, '**/*.so')].each do |so_file|
    puts so_file
  end
end
