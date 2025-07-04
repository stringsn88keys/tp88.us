## search for an encoding that works for "Mitterleuropäische Zeit" output in

puts Time.now.getlocal.zone.force_encoding(Encoding::UTF_8)
# "Mitteleurop\xE4ische Zeit"
puts Time.now.getlocal.zone
# => "Mitteleurop\xE4ische Zeit"
foo = Time.now.getlocal.zone
puts foo.encoding
# IBM437
puts foo.encode!(Encoding::UTF_8)
# "MitteleuropΣische Zeit"

bytes = [77, 105, 116, 116, 101, 108, 117, 114, 111, 112, 228, 105, 115, 99, 104, 101, 32, 90, 101, 105, 116]

def cycle_bytes(bytes)
  Encoding.list.each do |source|
    begin
      puts source
      puts bytes.pack("c*").force_encoding(source).encode("UTF-8")
    rescue Encoding::UndefinedConversionError => e
  #    puts source, "failed"
    end
  end
end

cycle_bytes([96])



