$:.each do |path|
  Dir[File.join(path, '**/*.dll')].each do |dll_file|
    puts dll_file
  end
end
