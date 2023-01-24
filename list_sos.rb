$:.each do |path|
  Dir[File.join(path, '**/*.so')].each do |so_file|
    puts so_file
  end
end
