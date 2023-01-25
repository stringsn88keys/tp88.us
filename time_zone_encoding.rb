## demonstration of various strings' encoding in ruby

lines=<<-LINES
  Time.now.zone
  Time.now.localtime.zone
  "EST"
  Time.now.localtime.zone.encode("".encoding)
  ""
  String.new("")
  String.new
LINES

puts "Encoding of various strings"
puts "---------------------------"

lines.each_line.each_with_index do |line, index|
  puts "#{line.strip} #=> \"#{eval line}\"" unless line.strip =~ /^"/
  puts "#{line.strip}.encoding #=> #{(eval line).encoding}"
end

puts "\nDoes any source/target encoding of time zone match \"Mitteleuropäische Zeit\" (CET in German)?\n"

Encoding.list.each do |source|
  time_zone=Time.now.zone
  if time_zone.include?("Mitteleuropäische Zeit")
    puts "Time zone matches without forcing encoding"
  end
  begin
    time_zone_force_encoded=time_zone.force_encoding(source).encode("UTF-8")
    if time_zone_force_encoded.include?("Mitteleuropäische Zeit")
      puts "Time zone matches if encoding is forced to #{source}"
    end
  rescue
    # some converters aren't meant to be, anyway
  end
end
