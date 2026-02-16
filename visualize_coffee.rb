#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'date'
require 'erb'
require 'json'
require 'optparse'

OZ_TO_GRAMS = 28.3495
SIMULTANEOUS_THRESHOLD_OZ_PER_DAY = 3.0

options = { output: 'coffee.html' }
OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
  opts.on("-o", "--output FILE", "Output HTML file (default: coffee.html)") { |f| options[:output] = f }
  opts.on("-h", "--help", "Show this help message") { puts opts; exit }
end.parse!

# Load coffee data
csv_file = File.join(__dir__, 'data', 'coffee.csv')
bags = CSV.read(csv_file, headers: true).map do |row|
  date_str = row['Date'].tr('/', '-')
  {
    date: Date.parse(date_str),
    cost: row['Cost'].to_s.gsub(/[^0-9.]/, '').to_f,
    store: row['Store'].to_s.strip,
    name: row['Name'].to_s.strip,
    size_oz: row['Size'].to_s.gsub(/[^0-9.]/, '').to_f
  }
end.sort_by { |b| b[:date] }

# Group bags into consumption periods.
# If consuming the current group's total oz in the time before the next purchase
# would exceed 3oz/day, the next bag is concurrent (open simultaneously).
groups = []
current_group = [bags.first]

bags.each_cons(2) do |_prev, nxt|
  group_start = current_group.first[:date]
  days_to_next = (nxt[:date] - group_start).to_i
  group_oz = current_group.sum { |b| b[:size_oz] }

  if days_to_next > 0 && (group_oz.to_f / days_to_next) > SIMULTANEOUS_THRESHOLD_OZ_PER_DAY
    # Too fast — bags must be open simultaneously
    current_group << nxt
  else
    # Finalize current group, start new one
    groups << { bags: current_group, start: group_start, end_date: nxt[:date] }
    current_group = [nxt]
  end
end

# Last group: project end date using 30-day trailing average consumption rate
groups << { bags: current_group, start: current_group.first[:date], end_date: Date.today }

if groups.length > 1
  last_group = groups.last
  lookback_start = last_group[:start] - 30
  last_group_oz = last_group[:bags].sum { |b| b[:size_oz] }

  trailing_grams = 0.0
  trailing_days = 0

  groups[0..-2].each do |g|
    g_total_oz = g[:bags].sum { |b| b[:size_oz] }
    g_days = (g[:end_date] - g[:start]).to_i
    g_days = 1 if g_days < 1
    g_rate_gpd = g_total_oz * OZ_TO_GRAMS / g_days.to_f

    overlap_start = [g[:start], lookback_start].max
    overlap_end = [g[:end_date], last_group[:start]].min
    overlap_days = (overlap_end - overlap_start).to_i

    if overlap_days > 0
      trailing_grams += overlap_days * g_rate_gpd
      trailing_days += overlap_days
    end
  end

  if trailing_days > 0
    avg_gpd = trailing_grams / trailing_days.to_f
    projected_days = (last_group_oz * OZ_TO_GRAMS / avg_gpd).ceil
    last_group[:end_date] = last_group[:start] + projected_days
    last_group[:projected] = true
  end
end

# Calculate per-group metrics
groups.each do |g|
  days = (g[:end_date] - g[:start]).to_i
  days = 1 if days < 1
  g[:days] = days
  g[:total_oz] = g[:bags].sum { |b| b[:size_oz] }
  g[:total_cost] = g[:bags].sum { |b| b[:cost] }
  g[:oz_per_day] = g[:total_oz] / days.to_f
  g[:g_per_day] = g[:oz_per_day] * OZ_TO_GRAMS
  g[:cost_per_day] = g[:total_cost] / days.to_f
end

# Aggregate by month: for each group, distribute its days across months
monthly_grams = Hash.new(0.0)
monthly_cost = Hash.new(0.0)
monthly_days = Hash.new(0)

groups.each do |g|
  current = g[:start]
  while current < g[:end_date]
    month_key = current.strftime("%Y-%m")
    month_end = Date.new(current.year, current.month, -1) + 1 # first of next month
    period_end = [month_end, g[:end_date]].min
    days_in_month = (period_end - current).to_i

    monthly_grams[month_key] += days_in_month * g[:g_per_day]
    monthly_cost[month_key] += days_in_month * g[:cost_per_day]
    monthly_days[month_key] += days_in_month

    current = period_end
  end
end

sorted_months = monthly_grams.keys.sort

# Monthly averages (g/day and $/day for each month)
monthly_g_per_day = sorted_months.map { |m| (monthly_grams[m] / monthly_days[m]).round(1) }
monthly_cost_per_day = sorted_months.map { |m| (monthly_cost[m] / monthly_days[m]).round(2) }
monthly_grams_totals = sorted_months.map { |m| monthly_grams[m].round(0) }
monthly_cost_totals = sorted_months.map { |m| monthly_cost[m].round(2) }

# Yearly aggregation
yearly_grams = Hash.new(0.0)
yearly_cost = Hash.new(0.0)
yearly_days = Hash.new(0)

sorted_months.each do |m|
  year = m.split('-').first.to_i
  yearly_grams[year] += monthly_grams[m]
  yearly_cost[year] += monthly_cost[m]
  yearly_days[year] += monthly_days[m]
end

sorted_years = yearly_grams.keys.sort
yearly_g_per_day = sorted_years.map { |y| (yearly_grams[y] / yearly_days[y]).round(1) }
yearly_cost_per_day = sorted_years.map { |y| (yearly_cost[y] / yearly_days[y]).round(2) }
yearly_grams_totals = sorted_years.map { |y| yearly_grams[y].round(0) }
yearly_cost_totals = sorted_years.map { |y| yearly_cost[y].round(2) }

# Summary stats
total_bags = bags.length
total_spent = bags.sum { |b| b[:cost] }
total_days = (Date.today - bags.first[:date]).to_i
total_days = 1 if total_days < 1
total_oz = bags.sum { |b| b[:size_oz] }
avg_g_per_day = (total_oz * OZ_TO_GRAMS / total_days).round(1)
avg_cost_per_day = (total_spent / total_days).round(2)

# Build table rows
table_rows = bags.reverse.map do |b|
  name_html = b[:name].empty? ? '<em>unnamed</em>' : ERB::Util.html_escape(b[:name])
  store_html = b[:store].empty? ? '<em>unknown</em>' : ERB::Util.html_escape(b[:store])
  <<~ROW
    <tr>
      <td>#{ERB::Util.html_escape(b[:date].strftime("%Y-%m-%d"))}</td>
      <td>#{name_html}</td>
      <td>#{store_html}</td>
      <td>#{b[:size_oz]}oz (#{(b[:size_oz] * OZ_TO_GRAMS).round(0)}g)</td>
      <td>$#{'%.2f' % b[:cost]}</td>
    </tr>
  ROW
end.join

# Build group detail rows
group_rows = groups.map do |g|
  bag_names = g[:bags].map { |b| b[:name].empty? ? 'unnamed' : b[:name] }.join(' + ')
  simultaneous = g[:bags].length > 1 ? ' (simultaneous)' : ''
  end_label = g[:end_date].strftime("%Y-%m-%d")
  end_label = "~#{end_label} (est.)" if g[:projected]
  <<~ROW
    <tr>
      <td>#{g[:start].strftime("%Y-%m-%d")} &rarr; #{end_label}</td>
      <td>#{ERB::Util.html_escape(bag_names)}#{simultaneous}</td>
      <td>#{g[:days]}</td>
      <td>#{g[:total_oz]}oz (#{(g[:total_oz] * OZ_TO_GRAMS).round(0)}g)</td>
      <td>#{g[:g_per_day].round(1)} g/day</td>
      <td>$#{'%.2f' % g[:cost_per_day]}/day</td>
    </tr>
  ROW
end.join

html_output = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Coffee Consumption Visualization</title>
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
      color: #6f4e37;
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
    .coffee-table {
      width: 100%;
      border-collapse: collapse;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin-bottom: 30px;
    }
    .coffee-table th, .coffee-table td {
      padding: 12px 15px;
      text-align: left;
      border-bottom: 1px solid #eee;
    }
    .coffee-table th {
      background: #6f4e37;
      color: white;
      font-weight: 600;
    }
    .coffee-table tr:hover { background: #f8f9fa; }
    .footer {
      margin-top: 20px;
      text-align: center;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <h1>Coffee Consumption Visualization</h1>

  <div class="summary">
    <div class="stat-card">
      <h3>Total Bags</h3>
      <div class="value">#{total_bags}</div>
    </div>
    <div class="stat-card">
      <h3>Total Spent</h3>
      <div class="value">$#{'%.2f' % total_spent}</div>
    </div>
    <div class="stat-card">
      <h3>Avg g/day</h3>
      <div class="value">#{avg_g_per_day}</div>
    </div>
    <div class="stat-card">
      <h3>Avg Cost/Day</h3>
      <div class="value">$#{'%.2f' % avg_cost_per_day}</div>
    </div>
  </div>

  <div class="chart-container">
    <h2>Grams per Day by Month</h2>
    <div class="chart-wrapper">
      <canvas id="monthlyGramsChart"></canvas>
    </div>
  </div>

  <div class="chart-container">
    <h2>Cost per Day by Month</h2>
    <div class="chart-wrapper">
      <canvas id="monthlyCostChart"></canvas>
    </div>
  </div>

  <h2>Consumption Periods</h2>
  <table class="coffee-table">
    <thead>
      <tr>
        <th>Period</th>
        <th>Bag(s)</th>
        <th>Days</th>
        <th>Total Size</th>
        <th>Usage Rate</th>
        <th>Cost Rate</th>
      </tr>
    </thead>
    <tbody>
#{group_rows}
    </tbody>
  </table>

  <h2>Purchase History</h2>
  <table class="coffee-table">
    <thead>
      <tr>
        <th>Date</th>
        <th>Name</th>
        <th>Store</th>
        <th>Size</th>
        <th>Cost</th>
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
    const monthlyLabels = #{sorted_months.to_json};
    const monthlyGPerDay = #{monthly_g_per_day.to_json};
    const monthlyCostPerDay = #{monthly_cost_per_day.to_json};
    const monthlyGramsTotals = #{monthly_grams_totals.to_json};
    const monthlyCostTotals = #{monthly_cost_totals.to_json};

    new Chart(document.getElementById('monthlyGramsChart').getContext('2d'), {
      type: 'bar',
      data: {
        labels: monthlyLabels,
        datasets: [{
          label: 'g/day',
          data: monthlyGPerDay,
          backgroundColor: 'rgba(111, 78, 55, 0.7)',
          borderColor: 'rgba(111, 78, 55, 1)',
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
              label: function(ctx) {
                return [
                  'Avg: ' + ctx.raw + ' g/day',
                  'Total: ' + monthlyGramsTotals[ctx.dataIndex] + ' g'
                ];
              }
            }
          }
        },
        scales: {
          y: { beginAtZero: true, title: { display: true, text: 'Grams per Day' } },
          x: { title: { display: true, text: 'Month' } }
        }
      }
    });

    new Chart(document.getElementById('monthlyCostChart').getContext('2d'), {
      type: 'bar',
      data: {
        labels: monthlyLabels,
        datasets: [{
          label: '$/day',
          data: monthlyCostPerDay,
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
              label: function(ctx) {
                return [
                  'Avg: $' + ctx.raw.toFixed(2) + '/day',
                  'Total: $' + monthlyCostTotals[ctx.dataIndex].toFixed(2)
                ];
              }
            }
          }
        },
        scales: {
          y: { beginAtZero: true, title: { display: true, text: '$ per Day' } },
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
puts "  Total bags: #{total_bags}"
puts "  Total spent: $#{'%.2f' % total_spent}"
puts "  Avg g/day: #{avg_g_per_day}"
puts "  Avg cost/day: $#{'%.2f' % avg_cost_per_day}"
