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

lines.each_line.each_with_index do |line, index|
  puts "#{line.strip} #=> \"#{eval line}\"" unless line.strip =~ /^"/
  puts "#{line.strip}.encoding #=> #{(eval line).encoding}"
end
