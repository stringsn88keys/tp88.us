#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'
require 'erb'
require 'json'
require 'optparse'

# Parse command line options
options = { show_all: true }
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"

  opts.on("-c", "--completed-only", "Show only completed books") do
    options[:show_all] = false
  end

  opts.on("-a", "--all", "Show all books (default)") do
    options[:show_all] = true
  end

  opts.on("-o", "--output FILE", "Output HTML file (default: books_visualization.html)") do |file|
    options[:output] = file
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!

options[:output] ||= "books_visualization.html"

# Load books data
books_file = File.join(__dir__, 'data', 'books.yml')
books = YAML.load_file(books_file, permitted_classes: [Date])

# Helper to parse page count from string like "325 pages"
def parse_pages(print_length)
  return 0 unless print_length
  match = print_length.match(/(\d+)\s*pages?/i)
  match ? match[1].to_i : 0
end

# Helper to parse time duration like "10 hours and 16 minutes" to minutes
def parse_duration_to_minutes(duration_str)
  return 0 unless duration_str
  hours = duration_str.match(/(\d+)\s*hours?/i)&.[](1).to_i
  minutes = duration_str.match(/(\d+)\s*minutes?/i)&.[](1).to_i
  hours * 60 + minutes
end

# Helper to parse percent like "22%"
def parse_percent(percent_str)
  return nil unless percent_str
  match = percent_str.to_s.match(/(\d+(?:\.\d+)?)\s*%/)
  match ? match[1].to_f / 100.0 : nil
end

# Calculate pages read for a book
def calculate_pages_read(book)
  total_pages = parse_pages(book['print_length'])
  return 0 if total_pages.zero?

  # If book is finished, all pages are read
  if book['date_finished'] && !book['date_finished'].to_s.empty?
    return total_pages
  end

  # Check for percent_complete
  if book['percent_complete']
    percent = parse_percent(book['percent_complete'])
    return (total_pages * percent).round if percent
  end

  # Check for time_left with listening_length (audiobooks)
  if book['time_left'] && book['listening_length']
    total_minutes = parse_duration_to_minutes(book['listening_length'])
    remaining_minutes = parse_duration_to_minutes(book['time_left'])
    if total_minutes > 0
      progress = (total_minutes - remaining_minutes).to_f / total_minutes
      return (total_pages * progress).round
    end
  end

  0
end

# Determine the month/year for a book's pages
def get_book_date(book)
  if book['date_finished'] && !book['date_finished'].to_s.empty?
    date = book['date_finished']
    date = Date.parse(date.to_s) unless date.is_a?(Date)
    date
  else
    Date.today
  end
end

# Check if book is completed
def completed?(book)
  book['date_finished'] && !book['date_finished'].to_s.empty?
end

# Process books based on options
filtered_books = options[:show_all] ? books : books.select { |b| completed?(b) }

# Aggregate data by year and month
monthly_data = Hash.new { |h, k| h[k] = Hash.new(0) }
yearly_data = Hash.new(0)
book_details = []

filtered_books.each do |book|
  pages_read = calculate_pages_read(book)
  date = get_book_date(book)
  year = date.year
  month = date.month
  month_key = date.strftime("%Y-%m")

  monthly_data[year][month] += pages_read
  yearly_data[year] += pages_read

  book_details << {
    title: book['title'],
    author: book['author'],
    pages_read: pages_read,
    total_pages: parse_pages(book['print_length']),
    date: date,
    completed: completed?(book),
    month_key: month_key
  }
end

# Sort data for charts
sorted_years = yearly_data.keys.sort
sorted_months = monthly_data.flat_map do |year, months|
  months.keys.map { |m| [year, m] }
end.sort.map { |y, m| Date.new(y, m, 1).strftime("%Y-%m") }.uniq

# Prepare monthly totals in order
monthly_totals = sorted_months.map do |month_key|
  year, month = month_key.split('-').map(&:to_i)
  monthly_data[year][month]
end

# Build table rows separately
table_rows = book_details.sort_by { |b| b[:date] }.reverse.map do |b|
  progress = b[:total_pages] > 0 ? "#{(b[:pages_read].to_f / b[:total_pages] * 100).round}%" : "N/A"
  status_class = b[:completed] ? 'status-completed' : 'status-reading'
  status_text = b[:completed] ? 'Completed' : 'Reading'
  <<~ROW
    <tr>
      <td>#{ERB::Util.html_escape(b[:title])}</td>
      <td>#{ERB::Util.html_escape(b[:author])}</td>
      <td>#{b[:pages_read]}</td>
      <td>#{b[:total_pages]}</td>
      <td>#{progress}</td>
      <td>#{b[:date].strftime("%Y-%m-%d")}</td>
      <td class="#{status_class}">#{status_text}</td>
    </tr>
  ROW
end.join

# Generate HTML
total_pages_read = book_details.sum { |b| b[:pages_read] }
formatted_pages = total_pages_read.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
completed_count = book_details.count { |b| b[:completed] }
in_progress_count = book_details.count { |b| !b[:completed] }
filter_text = options[:show_all] ? 'All Books' : 'Completed Books Only'

html_output = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Books Reading Visualization</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
      background: #f5f5f5;
      color: #333;
    }
    h1, h2 { color: #2c3e50; }
    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }
    .stat-card {
      background: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      text-align: center;
    }
    .stat-card h3 {
      margin: 0 0 10px 0;
      color: #7f8c8d;
      font-size: 0.9em;
      text-transform: uppercase;
    }
    .stat-card .value {
      font-size: 2em;
      font-weight: bold;
      color: #3498db;
    }
    .chart-container {
      background: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-bottom: 30px;
    }
    .chart-wrapper {
      position: relative;
      height: 400px;
    }
    .books-table {
      width: 100%;
      border-collapse: collapse;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .books-table th, .books-table td {
      padding: 12px 15px;
      text-align: left;
      border-bottom: 1px solid #eee;
    }
    .books-table th {
      background: #3498db;
      color: white;
      font-weight: 600;
    }
    .books-table tr:hover { background: #f8f9fa; }
    .status-completed { color: #27ae60; font-weight: bold; }
    .status-reading { color: #f39c12; font-weight: bold; }
    .filter-info {
      background: #e8f4fd;
      padding: 10px 15px;
      border-radius: 5px;
      margin-bottom: 20px;
      border-left: 4px solid #3498db;
    }
  </style>
</head>
<body>
  <h1>Books Reading Visualization</h1>

  <div class="filter-info">
    Showing: <strong>#{filter_text}</strong>
  </div>

  <div class="summary">
    <div class="stat-card">
      <h3>Total Books</h3>
      <div class="value">#{filtered_books.count}</div>
    </div>
    <div class="stat-card">
      <h3>Total Pages Read</h3>
      <div class="value">#{formatted_pages}</div>
    </div>
    <div class="stat-card">
      <h3>Completed</h3>
      <div class="value">#{completed_count}</div>
    </div>
    <div class="stat-card">
      <h3>In Progress</h3>
      <div class="value">#{in_progress_count}</div>
    </div>
  </div>

  <div class="chart-container">
    <h2>Pages Read by Year</h2>
    <div class="chart-wrapper">
      <canvas id="yearlyChart"></canvas>
    </div>
  </div>

  <div class="chart-container">
    <h2>Pages Read by Month</h2>
    <div class="chart-wrapper">
      <canvas id="monthlyChart"></canvas>
    </div>
  </div>

  <h2>Book Details</h2>
  <table class="books-table">
    <thead>
      <tr>
        <th>Title</th>
        <th>Author</th>
        <th>Pages Read</th>
        <th>Total Pages</th>
        <th>Progress</th>
        <th>Date</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
#{table_rows}
    </tbody>
  </table>

  <script>
    const yearlyCtx = document.getElementById('yearlyChart').getContext('2d');
    new Chart(yearlyCtx, {
      type: 'bar',
      data: {
        labels: #{sorted_years.to_json},
        datasets: [{
          label: 'Pages Read',
          data: #{sorted_years.map { |y| yearly_data[y] }.to_json},
          backgroundColor: 'rgba(52, 152, 219, 0.7)',
          borderColor: 'rgba(52, 152, 219, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, title: { display: true, text: 'Pages' } },
          x: { title: { display: true, text: 'Year' } }
        }
      }
    });

    const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
    new Chart(monthlyCtx, {
      type: 'line',
      data: {
        labels: #{sorted_months.to_json},
        datasets: [{
          label: 'Pages Read',
          data: #{monthly_totals.to_json},
          backgroundColor: 'rgba(46, 204, 113, 0.2)',
          borderColor: 'rgba(46, 204, 113, 1)',
          borderWidth: 2,
          fill: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, title: { display: true, text: 'Pages' } },
          x: { title: { display: true, text: 'Month' } }
        }
      }
    });
  </script>
</body>
</html>
HTML

File.write(options[:output], html_output)
puts "Generated: #{options[:output]}"
puts "  Total books: #{filtered_books.count}"
puts "  Total pages read: #{total_pages_read}"
puts "  Mode: #{options[:show_all] ? 'All books' : 'Completed only'}"
