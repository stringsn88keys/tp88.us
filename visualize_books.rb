#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'date'
require 'erb'
require 'json'
require 'optparse'
require 'set'

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

# Load books data from both sources
books_file = File.join(__dir__, 'data', 'books.yml')
books = YAML.load_file(books_file, permitted_classes: [Date])
books.each { |b| b['source'] ||= 'manual' }

goodreads_file = File.join(__dir__, 'data', 'books_goodreads.yml')
if File.exist?(goodreads_file)
  goodreads_books = YAML.load_file(goodreads_file, permitted_classes: [Date]) || []
  # Deduplicate: prefer manual books.yml entries over Goodreads
  manual_titles = books.map { |b| b['title'].to_s.downcase.strip }.to_set
  goodreads_books.each do |gb|
    unless manual_titles.include?(gb['title'].to_s.downcase.strip)
      books << gb
    end
  end
  puts "Loaded #{goodreads_books.size} Goodreads books (#{books.size} total after dedup)"
end

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
  seconds = duration_str.match(/(\d+)\s*seconds?/i)&.[](1).to_i
  hours * 60 + minutes + (1/60.0) * seconds
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
  total_pages = parse_pages(book['print_length'])
  is_completed = completed?(book)

  if is_completed
    # Completed books: assign all pages to finish date
    date = get_book_date(book)
    year = date.year
    month = date.month
    month_key = date.strftime("%Y-%m")

    monthly_data[year][month] += pages_read
    yearly_data[year] += pages_read

    full_title = book['subtitle'] ? "#{book['title']}: #{book['subtitle']}" : book['title']
    book_details << {
      title: full_title,
      author: book['author'],
      pages_read: pages_read,
      total_pages: total_pages,
      date: date,
      completed: true,
      month_key: month_key,
      associates_link: book['associates_link'],
      rating: book['rating'],
      source: book['source'] || 'manual'
    }
  else
    # In-progress books: distribute pages evenly from date_started to today
    date_started = book['date_started']
    if date_started
      date_started = Date.parse(date_started.to_s) unless date_started.is_a?(Date)
      end_date = Date.today
      total_days = (end_date - date_started).to_i + 1
      pages_per_day = total_days > 0 ? pages_read.to_f / total_days : 0

      # Iterate through each month from start to today
      current = date_started
      while current <= end_date
        month_start = Date.new(current.year, current.month, 1)
        month_end = Date.new(current.year, current.month, -1)
        # Clamp to actual reading period
        period_start = [month_start, date_started].max
        period_end = [month_end, end_date].min
        days_in_month = (period_end - period_start).to_i + 1

        month_pages = (days_in_month * pages_per_day).round
        monthly_data[current.year][current.month] += month_pages
        yearly_data[current.year] += month_pages

        # Move to next month
        current = Date.new(current.year, current.month, 1).next_month
      end
    else
      # No date_started, fall back to today
      end_date = Date.today
      monthly_data[end_date.year][end_date.month] += pages_read
      yearly_data[end_date.year] += pages_read
    end

    full_title = book['subtitle'] ? "#{book['title']}: #{book['subtitle']}" : book['title']
    book_details << {
      title: full_title,
      author: book['author'],
      pages_read: pages_read,
      total_pages: total_pages,
      date: Date.today,
      completed: false,
      month_key: Date.today.strftime("%Y-%m"),
      associates_link: book['associates_link'],
      rating: book['rating'],
      source: book['source'] || 'manual'
    }
  end
end

# Sort data for charts
sorted_years = yearly_data.keys.sort
sorted_months = monthly_data.flat_map do |year, months|
  months.keys.map { |m| [year, m] }
end.sort.map { |y, m| Date.new(y, m, 1).strftime("%Y-%m") }.uniq

# Prepare monthly totals in order
today = Date.today
monthly_totals = sorted_months.map do |month_key|
  year, month = month_key.split('-').map(&:to_i)
  monthly_data[year][month]
end

# Calculate days for each month (current date for current month, full days for past months)
monthly_days = sorted_months.map do |month_key|
  year, month = month_key.split('-').map(&:to_i)
  if year == today.year && month == today.month
    today.day
  else
    Date.new(year, month, -1).day # Last day of month
  end
end

# Calculate pages per day for each month
monthly_pages_per_day = monthly_totals.zip(monthly_days).map do |pages, days|
  days > 0 ? (pages.to_f / days).round(1) : 0
end

# Calculate days for each year (current date for current year, full days for past years)
yearly_days = sorted_years.map do |year|
  if year == today.year
    today.yday
  else
    Date.new(year, 12, 31).yday
  end
end

# Calculate pages per day for each year
yearly_pages_per_day = sorted_years.map.with_index do |year, idx|
  pages = yearly_data[year]
  days = yearly_days[idx]
  days > 0 ? (pages.to_f / days).round(1) : 0
end

# Build table rows separately
table_rows = book_details.sort_by { |b| b[:date] }.reverse.map do |b|
  progress = b[:total_pages] > 0 ? "#{(b[:pages_read].to_f / b[:total_pages] * 100).round}%" : "N/A"
  status_class = b[:completed] ? 'status-completed' : 'status-reading'
  status_text = b[:completed] ? 'Completed' : 'Reading'
  title_html = ERB::Util.html_escape(b[:title])
  if b[:associates_link]
    title_html += " <sub><a href=\"#{ERB::Util.html_escape(b[:associates_link])}\">(affiliate link)</a></sub>"
  end
  rating_html = if b[:rating] && b[:rating] > 0
                  stars = "\u2605" * b[:rating] + "\u2606" * (5 - b[:rating])
                  "<span title=\"#{b[:rating]}/5\">#{stars}</span>"
                else
                  "\u2014"
                end
  source_html = b[:source] == 'goodreads' ? '<span class="source-goodreads">GR</span>' : '<span class="source-manual">Manual</span>'
  <<~ROW
    <tr>
      <td>#{title_html}</td>
      <td>#{ERB::Util.html_escape(b[:author])}</td>
      <td>#{rating_html}</td>
      <td>#{b[:pages_read]}</td>
      <td>#{b[:total_pages]}</td>
      <td>#{progress}</td>
      <td>#{b[:date].strftime("%Y-%m-%d")}</td>
      <td class="#{status_class}">#{status_text}</td>
      <td>#{source_html}</td>
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
    .source-goodreads { color: #999; font-size: 0.8em; }
    .source-manual { color: #3498db; font-size: 0.8em; }
    .filter-info {
      background: #e8f4fd;
      padding: 10px 15px;
      border-radius: 5px;
      margin-bottom: 20px;
      border-left: 4px solid #3498db;
    }
    .footer {
      margin-top: 20px;
      text-align: center;
      font-size: 14px;
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
        <th>Rating</th>
        <th>Pages Read</th>
        <th>Total Pages</th>
        <th>Progress</th>
        <th>Date</th>
        <th>Status</th>
        <th>Source</th>
      </tr>
    </thead>
    <tbody>
#{table_rows}
    </tbody>
  </table>

  <div class="footer">
    <a href="/">Back to Index</a>
  </div>

  <script>
    const yearlyPagesPerDay = #{yearly_pages_per_day.to_json};
    const monthlyPagesPerDay = #{monthly_pages_per_day.to_json};

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
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const pages = context.raw;
                const ppd = yearlyPagesPerDay[context.dataIndex];
                return ['Pages Read: ' + pages.toLocaleString(), 'Pages per Day: ' + ppd];
              }
            }
          }
        },
        scales: {
          y: { beginAtZero: true, title: { display: true, text: 'Pages' } },
          x: { title: { display: true, text: 'Year' } }
        }
      }
    });

    const monthlyCtx = document.getElementById('monthlyChart').getContext('2d');
    new Chart(monthlyCtx, {
      type: 'bar',
      data: {
        labels: #{sorted_months.to_json},
        datasets: [{
          label: 'Pages Read',
          data: #{monthly_totals.to_json},
          backgroundColor: 'rgba(46, 204, 113, 0.7)',
          borderColor: 'rgba(46, 204, 113, 1)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(context) {
                const pages = context.raw;
                const ppd = monthlyPagesPerDay[context.dataIndex];
                return ['Pages Read: ' + pages.toLocaleString(), 'Pages per Day: ' + ppd];
              }
            }
          }
        },
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
