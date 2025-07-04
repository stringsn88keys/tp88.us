## Tally Robinhood transactions
require 'csv'


module Robinhood
  refine String do
    def from_dollar
      self.gsub(/[$,]/, '').gsub(/\((.*)\)/, '-\1').to_f
    end
  end
end

using Robinhood


tally = {}
ARGV.each do |file|
  CSV.open(file, 'r', headers: true) do |csv|
    csv.each do |row|
      next if row['Instrument'].nil?
      tally[row['Instrument']] ||= {}
      case row['Trans Code']
      when 'Buy'
        tally[row['Instrument']]['Invested'] ||= 0
        tally[row['Instrument']]['Invested'] += row['Amount']&.from_dollar
        tally[row['Instrument']]['Shares'] ||= 0
        tally[row['Instrument']]['Shares'] += (row['Quantity']&.from_dollar || 0)
      when 'Sell'
        tally[row['Instrument']]['Proceeds'] ||= 0
        tally[row['Instrument']]['Proceeds'] += row['Amount']&.from_dollar
        tally[row['Instrument']]['Shares'] ||= 0
        tally[row['Instrument']]['Shares'] += (row['Quantity']&.from_dollar || 0)
      when 'CDIV'
        tally[row['Instrument']]['Dividends'] ||= 0
        tally[row['Instrument']]['Dividends'] += row['Amount']&.from_dollar
      when 'STO', 'STC'
        tally[row['Instrument']]['Sold Options'] ||= 0
        tally[row['Instrument']]['Sold Options'] += row['Amount']&.from_dollar
        tally[row['Instrument']]['Contracts'] ||= 0
        tally[row['Instrument']]['Contracts'] -= (row['Quantity']&.to_f || 0)
      when 'OEXP'
        if row['Description'] =~ /Call/
          tally[row['Instrument']]['Contracts'] ||= 0
          tally[row['Instrument']]['Contracts'] += row['Quantity']&.to_f || 0
        end
      when 'BTO', 'BTC'
        tally[row['Instrument']]['Bought Options'] ||= 0
        tally[row['Instrument']]['Bought Options'] += row['Amount']&.from_dollar
        tally[row['Instrument']]['Contracts'] ||= 0
        tally[row['Instrument']]['Contracts'] += (row['Quantity']&.to_f || 0)
      end
    end
  end
end

tally.each do |k, v|
  net_profit = (v['Proceeds'] || 0.0) + (v['Invested'] || 0.0) + (v['Dividends'] || 0.0) + (v['Sold Options'] || 0.0) + (v['Bought Options'] || 0.0)
  if v['Proceeds']
    tally[k]['Net Profit'] = net_profit
  else
    tally[k]['Cost per Share'] = net_profit / (v['Shares'] || 1)
  end
end

tally.keys.sort.each do |k|
  puts "#{k} #{tally[k]}"
end
