#!/usr/bin/env ruby

require 'erb'

class ConspiracyBoardGenerator
  def initialize
    @notes = [
      {
        id: 'openssl_gem',
        content: "OpenSSL GEM<br>ruby/openssl<br>VERSION: 3.2.0<br><strong>RUBY WRAPPER!</strong><br>NOT the actual crypto!",
        class: 'yellow',
        position: { top: 100, left: 50 },
        rotation: -5,
        pushpin: { top: 140, left: 125 }
      },
      {
        id: 'openssl_library',
        content: "OpenSSL LIBRARY<br>openssl/openssl<br>VERSION: 3.2.4<br><strong>ACTUAL C LIBRARY</strong><br>The real crypto stuff!",
        class: 'pink',
        position: { top: 160, left: 350 },
        rotation: 3,
        pushpin: { top: 200, left: 425 }
      },
      {
        id: 'fips_validation',
        content: "FIPS VALIDATION<br>Only for C library!<br>Validated versions:<br>• 3.0.8 ✓<br>• 3.0.9 ✓<br>• 3.1.2 ✓<br><strong>NOT 3.2.4!</strong>",
        class: 'green',
        position: { top: 230, left: 650 },
        rotation: -8,
        pushpin: { top: 270, left: 725 }
      },
      {
        id: 'nist_validation',
        content: "NIST VALIDATION<br>Takes FOREVER!<br>Expensive process!<br>Any code change =<br>RE-VALIDATION!",
        class: 'blue',
        position: { top: 320, left: 100 },
        rotation: 7,
        pushpin: { top: 360, left: 175 }
      },
      {
        id: 'provider_architecture',
        content: "PROVIDER ARCHITECTURE<br>OpenSSL 3.x uses<br>loadable modules<br>FIPS = separate provider<br>Must use EXACT validated one!",
        class: 'orange',
        position: { top: 400, left: 450 },
        rotation: -3,
        pushpin: { top: 440, left: 525 }
      },
      {
        id: 'version_mismatch',
        content: "VERSION MISMATCH<br>Gem 3.2.0 ≠ Library 3.2.4<br>Different repos!<br>Different numbering!<br>TOTALLY DIFFERENT!",
        class: 'pink',
        position: { top: 480, left: 800 },
        rotation: 6,
        pushpin: { top: 520, left: 875 }
      },
      {
        id: 'the_truth',
        content: "THE TRUTH:<br>Can't use 3.2.4 for FIPS<br>without separate validated<br>FIPS provider because<br>NO VALIDATION EXISTS!",
        class: 'yellow',
        position: { top: 580, left: 200 },
        rotation: -4,
        pushpin: { top: 620, left: 275 }
      },
      {
        id: 'dependency_chain',
        content: "DEPENDENCY CHAIN<br>Ruby App →<br>OpenSSL Gem →<br>OpenSSL Library →<br>FIPS Provider<br>ALL must align!",
        class: 'green',
        position: { top: 150, left: 900 },
        rotation: 8,
        pushpin: { top: 190, left: 975 }
      },
      {
        id: 'compliance_reality',
        content: "COMPLIANCE REALITY<br>Need:<br>• Validated C library<br>• Compatible gem<br>• Proper config<br>• Exact versions!",
        class: 'blue',
        position: { top: 350, left: 850 },
        rotation: -6,
        pushpin: { top: 390, left: 925 }
      },
      {
        id: 'pepe_silvia',
        content: "PEPE SILVIA MOMENT:<br>There IS no 3.2.4<br>FIPS validation!<br>It's all connected!<br>CAROL IN HR!",
        class: 'orange',
        position: { top: 50, left: 500 },
        rotation: 2,
        pushpin: { top: 90, left: 575 }
      },
      {
        id: 'separate_versions',
        content: "SEPARATE VERSIONS<br>You MUST maintain<br>different versions for<br>FIPS vs non-FIPS<br>because validation<br>locks you to specific<br>exact versions!",
        class: 'yellow',
        position: { top: 650, left: 500 },
        rotation: -7,
        pushpin: { top: 690, left: 575 }
      }
    ]

    @connections = [
      { from: 'openssl_gem', to: 'openssl_library' },
      { from: 'openssl_library', to: 'fips_validation' },
      { from: 'fips_validation', to: 'dependency_chain' },
      { from: 'nist_validation', to: 'provider_architecture' },
      { from: 'fips_validation', to: 'provider_architecture' },
      { from: 'fips_validation', to: 'separate_versions' },
      { from: 'provider_architecture', to: 'compliance_reality' },
      { from: 'version_mismatch', to: 'separate_versions' },
      { from: 'the_truth', to: 'separate_versions' },
      { from: 'pepe_silvia', to: 'fips_validation' }
    ]
  end

  def find_note(id)
    @notes.find { |note| note[:id] == id }
  end

  def calculate_string_properties(from_pin, to_pin)
    x1 = from_pin[:left]
    y1 = from_pin[:top]
    x2 = to_pin[:left]
    y2 = to_pin[:top]

    # Calculate distance
    length = Math.sqrt((x2 - x1)**2 + (y2 - y1)**2)

    # Calculate angle in degrees
    angle_rad = Math.atan2(y2 - y1, x2 - x1)
    angle_deg = angle_rad * 180 / Math::PI

    {
      start_x: x1,
      start_y: y1,
      length: length.round,
      angle: angle_deg.round(1)
    }
  end

  def generate_html
    template = ERB.new(html_template)
    template.result(binding)
  end

  def html_template
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>OpenSSL FIPS Compliance Explained</title>
          <style>
              body {
                  margin: 0;
                  padding: 20px;
                  background: linear-gradient(135deg, #8B4513 0%, #A0522D 100%);
                  font-family: 'Courier New', monospace;
                  min-height: 100vh;
                  overflow-x: auto;
              }
              
              .conspiracy-board {
                  position: relative;
                  width: 1200px;
                  height: 800px;
                  background: #F5DEB3;
                  border: 10px solid #654321;
                  box-shadow: 0 0 30px rgba(0,0,0,0.5);
                  margin: 0 auto;
              }
              
              .note {
                  position: absolute;
                  background: #FFE4B5;
                  border: 2px solid #8B4513;
                  padding: 8px;
                  font-size: 11px;
                  line-height: 1.2;
                  box-shadow: 3px 3px 8px rgba(0,0,0,0.3);
                  transform: rotate(-2deg);
                  max-width: 150px;
                  font-weight: bold;
              }
              
              .note.yellow { background: #FFFF99; }
              .note.pink { background: #FFB6C1; }
              .note.green { background: #90EE90; }
              .note.blue { background: #87CEEB; }
              .note.orange { background: #FFD700; }
              
              .red-string {
                  position: absolute;
                  height: 2px;
                  background: #FF0000;
                  transform-origin: left center;
                  z-index: 1;
              }
              
              .red-string::before {
                  content: '';
                  position: absolute;
                  right: -4px;
                  top: -2px;
                  width: 0;
                  height: 0;
                  border-left: 6px solid #FF0000;
                  border-top: 3px solid transparent;
                  border-bottom: 3px solid transparent;
              }
              
              .title {
                  position: absolute;
                  top: 20px;
                  left: 50%;
                  transform: translateX(-50%);
                  font-size: 24px;
                  font-weight: bold;
                  color: #8B0000;
                  text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
              }
              
              .charlie-text {
                  position: absolute;
                  bottom: 20px;
                  right: 20px;
                  font-size: 14px;
                  color: #8B0000;
                  font-style: italic;
                  transform: rotate(1deg);
              }
              
              .pushpin {
                  position: absolute;
                  width: 12px;
                  height: 12px;
                  background: #FF0000;
                  border-radius: 50%;
                  box-shadow: 0 0 4px rgba(0,0,0,0.5);
                  z-index: 10;
              }
              
              .pushpin::before {
                  content: '';
                  position: absolute;
                  top: 2px;
                  left: 2px;
                  width: 8px;
                  height: 8px;
                  background: #800000;
                  border-radius: 50%;
              }
          </style>
      </head>
      <body>
          <div class="conspiracy-board">
              <div class="title">OPENSSL FIPS COMPLIANCE CONSPIRACY</div>
              
              <!-- Generated connections -->
              <% @connections.each do |connection| %>
                <% from_note = find_note(connection[:from]) %>
                <% to_note = find_note(connection[:to]) %>
                <% string_props = calculate_string_properties(from_note[:pushpin], to_note[:pushpin]) %>
                
                <!-- <%= connection[:from] %> to <%= connection[:to] %> -->
                <div class="pushpin" style="top: <%= from_note[:pushpin][:top] %>px; left: <%= from_note[:pushpin][:left] %>px;"></div>
                <div class="red-string" style="top: <%= string_props[:start_y] + 6 %>px; left: <%= string_props[:start_x] + 12 %>px; width: <%= string_props[:length] %>px; transform: rotate(<%= string_props[:angle] %>deg);"></div>
                <div class="pushpin" style="top: <%= to_note[:pushpin][:top] %>px; left: <%= to_note[:pushpin][:left] %>px;"></div>
              <% end %>
              
              <!-- Generated notes -->
              <% @notes.each do |note| %>
                <div class="note <%= note[:class] %>" style="top: <%= note[:position][:top] %>px; left: <%= note[:position][:left] %>px; transform: rotate(<%= note[:rotation] %>deg);">
                    <%= note[:content] %>
                </div>
              <% end %>
              
              <div class="charlie-text">
                  "Day bow bow... chik... chika-chika..."<br>
                  - Charlie Kelly, Cryptography Expert
              </div>
          </div>
      </body>
      </html>
    HTML
  end
end

# Generate the conspiracy board
generator = ConspiracyBoardGenerator.new
html_content = generator.generate_html

# Write to file
File.write('openssl_pepe_silvia_generated.html', html_content)

puts "Generated conspiracy board saved to openssl_pepe_silvia_generated.html"
puts "\nConnection details:"

generator.instance_variable_get(:@connections).each do |connection|
  from_note = generator.find_note(connection[:from])
  to_note = generator.find_note(connection[:to])
  string_props = generator.calculate_string_properties(from_note[:pushpin], to_note[:pushpin])
  
  puts "#{connection[:from]} -> #{connection[:to]}:"
  puts "  Length: #{string_props[:length]}px, Angle: #{string_props[:angle]}°"
  puts "  From: (#{from_note[:pushpin][:left]}, #{from_note[:pushpin][:top]}) To: (#{to_note[:pushpin][:left]}, #{to_note[:pushpin][:top]})"
  puts
end
