## List all DLL files found in Ruby's load path ($LOAD_PATH)
$:.each do |path|
  Dir[File.join(path, '**/*.dll')].each do |dll_file|
    puts dll_file
  end
end
