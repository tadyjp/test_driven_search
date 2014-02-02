#!/usr/bin/env ruby
# Usage:
#   $ ruby convert-csv.rb <something.csv>

require 'csv'
require 'json'

header = CSV.parse_line(STDIN.gets.chomp)

while line = STDIN.gets.chomp
  begin
    line_array = CSV.parse_line(line)
  rescue CSV::MalformedCSVError
  end

  puts ({ index: { _index: 'livedoor-gourmet', _type: 'restaurant'} }.to_json)
  puts Hash[header.zip(line_array)].to_json
end
