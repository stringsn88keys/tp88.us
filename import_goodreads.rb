#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'net/http'
require 'optparse'
require 'date'
require 'uri'
require 'shellwords'

options = {
  input: File.join(__dir__, 'data', 'Goodreads'),
  output: File.join(__dir__, 'data', 'books_goodreads.yml'),
  lookup: false,
  delay: 0.5
}

OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Import Goodreads export data into a YAML books file.

    Reads review.zip from a Goodreads data export directory, extracts books
    marked as "read", and writes them to a YAML file. Optionally enriches
    entries with author and page count data from the Open Library API.

    Usage: #{$PROGRAM_NAME} [options]

  BANNER

  opts.on("-i", "--input PATH", "Path to Goodreads directory (default: data/Goodreads)") do |path|
    options[:input] = path
  end

  opts.on("-o", "--output PATH", "Output YAML file (default: data/books_goodreads.yml)") do |path|
    options[:output] = path
  end

  opts.on("-l", "--lookup", "Enable Open Library API lookups for author/page data") do
    options[:lookup] = true
  end

  opts.on("--delay SECONDS", Float, "Delay between API calls (default: 0.5)") do |d|
    options[:delay] = d
  end

  opts.on("-u", "--usage", "Show usage examples") do
    puts <<~USAGE
      Examples:
        #{$PROGRAM_NAME}                              # Default import from data/Goodreads
        #{$PROGRAM_NAME} -l                            # Import with Open Library lookups
        #{$PROGRAM_NAME} -i ~/Downloads/Goodreads      # Custom input directory
        #{$PROGRAM_NAME} -o my_books.yml               # Custom output file
        #{$PROGRAM_NAME} -l --delay 1.0                # Lookups with 1s delay between API calls
    USAGE
    exit
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

# Read review.json from the zip
review_zip = File.join(options[:input], 'review.zip')
unless File.exist?(review_zip)
  abort "Error: #{review_zip} not found"
end

raw_json = `unzip -p #{review_zip.shellescape}`
reviews = JSON.parse(raw_json)

# Filter to read books only (skip explanation entries without read_status)
read_books = reviews.select { |r| r['read_status'] == 'read' }
puts "Found #{read_books.size} read books"

# Open Library cache
cache_path = File.join(__dir__, 'data', 'goodreads_openlibrary_cache.json')
ol_cache = if File.exist?(cache_path)
             JSON.parse(File.read(cache_path))
           else
             {}
           end

def strip_subtitle(title)
  # Strip subtitles and series info to improve Open Library match quality.
  # "Dopesick: Dealers, Doctors, and the Drug Company..." -> "Dopesick"
  # "Life Debt (Star Wars: Aftermath, #2)" -> "Life Debt"
  title.sub(/\s*[:(]\s*.*/, '').strip
end

def lookup_open_library(title, cache, delay)
  return cache[title] if cache.key?(title)

  search_title = strip_subtitle(title)
  encoded = URI.encode_www_form_component(search_title)
  url = "https://openlibrary.org/search.json?title=#{encoded}&limit=1&fields=title,author_name,number_of_pages_median"

  uri = URI(url)
  response = Net::HTTP.get_response(uri)

  if response.is_a?(Net::HTTPSuccess)
    data = JSON.parse(response.body)
    docs = data['docs']
    if docs && !docs.empty?
      doc = docs[0]
      result = {
        'author' => doc['author_name']&.first,
        'pages' => doc['number_of_pages_median']
      }
      cache[title] = result
      sleep delay
      return result
    end
  end

  cache[title] = { 'author' => nil, 'pages' => nil }
  sleep delay
  cache[title]
end

# Map books
books = read_books.map do |entry|
  book = {}
  book['title'] = entry['book']
  book['rating'] = entry['rating'] if entry['rating'] && entry['rating'] != 0

  # Parse dates - extract date portion from "2010-08-10 14:41:01 UTC"
  if entry['updated_at'] && entry['updated_at'] != '(not provided)'
    date_str = entry['updated_at'].split(' ').first
    book['date_finished'] = Date.parse(date_str)
  end

  if entry['created_at'] && entry['created_at'] != '(not provided)'
    date_str = entry['created_at'].split(' ').first
    book['date_started'] = Date.parse(date_str)
  end

  if entry['review'] && entry['review'] != '(not provided)'
    book['review'] = entry['review'].gsub("\r\n", "\n")
  end

  book['source'] = 'goodreads'

  # Open Library lookup
  if options[:lookup]
    ol = lookup_open_library(book['title'], ol_cache, options[:delay])
    book['author'] = ol['author'] if ol['author']
    book['print_length'] = "#{ol['pages']} pages" if ol['pages']
  end

  book
end

# Sort by date_finished descending
books.sort_by! { |b| b['date_finished'] || Date.new(1970, 1, 1) }.reverse!

# Save cache if lookups were performed
if options[:lookup]
  File.write(cache_path, JSON.pretty_generate(ol_cache))
  puts "Saved Open Library cache (#{ol_cache.size} entries)"
end

# Write YAML
File.write(options[:output], books.to_yaml)
puts "Wrote #{books.size} books to #{options[:output]}"

# Summary stats
with_rating = books.count { |b| b['rating'] }
with_review = books.count { |b| b['review'] }
with_author = books.count { |b| b['author'] }
with_pages = books.count { |b| b['print_length'] }
puts "  With rating: #{with_rating}"
puts "  With review: #{with_review}"
puts "  With author: #{with_author}"
puts "  With pages: #{with_pages}"
