#!/usr/bin/env ruby
## Scrapes current Florida Lottery jackpot amounts and saves to JSON

require 'net/http'
require 'json'

GAMES = {
  'powerball' => {
    name: 'Powerball w/ Double Play',
    default: 20_000_000
  },
  'florida-lotto' => {
    name: 'Florida Lotto w/ Double Play',
    default: 2_500_000
  },
  'fantasy5' => {
    name: 'Fantasy 5 w/ EZ Match',
    default: 250_000
  },
  'jackpot-triple-play' => {
    name: 'Jackpot Triple Play',
    default: 2_500_000
  }
}.freeze

def fetch_json(url, headers = {})
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.read_timeout = 10
  
  request = Net::HTTP::Get.new(uri.request_uri)
  request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'
  headers.each { |k, v| request[k] = v }
  
  response = http.request(request)
  JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
rescue StandardError => e
  puts "    Error: #{e.message}"
  nil
end

def scrape_from_lottery_api
  puts "Attempting to fetch from lottery data API..."
  
  # Try lotteryreader.com API (requires no auth for basic queries)
  begin
    data = fetch_json('https://lotteryreader.com/api/lottery/fl/draw-games')
    
    if data && data.is_a?(Array)
      jackpots = {}
      data.each do |game|
        case game['name']&.downcase
        when /powerball/
          jackpots['Powerball w/ Double Play'] = parse_amount(game['jackpot']) if game['jackpot']
        when /lotto/
          jackpots['Florida Lotto w/ Double Play'] = parse_amount(game['jackpot']) if game['jackpot']
        when /fantasy/
          jackpots['Fantasy 5 w/ EZ Match'] = parse_amount(game['jackpot']) if game['jackpot']
        when /triple/
          jackpots['Jackpot Triple Play'] = parse_amount(game['jackpot']) if game['jackpot']
        end
      end
      
      return jackpots if jackpots.size > 0
    end
  rescue StandardError => e
    puts "    lotteryreader.com API failed: #{e.message}"
  end
  
  # Fallback: try other API
  begin
    data = fetch_json('https://api.lottery.wtf/api/v1/lottery')
    if data && data['lotteries']
      jackpots = {}
      data['lotteries'].each do |name, game_data|
        if game_data['currentJackpot']
          amount = parse_amount(game_data['currentJackpot'])
          case name.downcase
          when /powerball/
            jackpots['Powerball w/ Double Play'] = amount
          when /lotto/
            jackpots['Florida Lotto w/ Double Play'] = amount
          when /fantasy/
            jackpots['Fantasy 5 w/ EZ Match'] = amount
          when /triple/
            jackpots['Jackpot Triple Play'] = amount
          end
        end
      end
      
      return jackpots if jackpots.size > 0
    end
  rescue StandardError => e
    puts "    lottery.wtf API failed: #{e.message}"
  end
  
  nil
end

def parse_amount(amount_str)
  return nil unless amount_str
  
  amount_str = amount_str.to_s.upcase
  
  if amount_str.include?('BILLION')
    base = amount_str.gsub(/[^\d.]/, '').to_f
    (base * 1_000_000_000).to_i
  elsif amount_str.include?('MILLION')
    base = amount_str.gsub(/[^\d.]/, '').to_f
    (base * 1_000_000).to_i
  else
    amount_str.gsub(/[^\d]/, '').to_i
  end
end

def get_default_jackpots
  puts "Using default jackpot amounts (no live data available)..."
  
  jackpots = {}
  GAMES.each do |key, game_info|
    jackpots[game_info[:name]] = game_info[:default]
    puts "  - #{game_info[:name]}: $#{game_info[:default].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end
  jackpots
end

def format_currency(amount)
  "$#{amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
end

def scrape_jackpots
  puts "Scraping Florida Lottery jackpots...\n\n"
  
  # Try to fetch live data
  jackpots = scrape_from_lottery_api
  
  if jackpots && jackpots.size > 0
    puts "\n✓ Successfully fetched live jackpot data:"
    jackpots.each do |name, amount|
      puts "  - #{name}: #{format_currency(amount)}"
    end
  else
    puts "\n⚠ Could not fetch live data, using defaults\n\n"
    jackpots = get_default_jackpots
  end
  
  jackpots
end

def save_jackpots(jackpots)
  output_file = 'data/lottery_jackpots.json'
  
  data = {
    updated_at: Time.now.to_s,
    source: 'Florida Lottery APIs',
    jackpots: jackpots
  }
  
  File.write(output_file, JSON.pretty_generate(data))
  puts "\n✓ Saved jackpots to #{output_file}"
rescue StandardError => e
  puts "\n✗ Error saving jackpots: #{e.message}"
end

if __FILE__ == $0
  jackpots = scrape_jackpots
  save_jackpots(jackpots) if jackpots && jackpots.size > 0
end

