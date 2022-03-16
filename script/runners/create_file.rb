require 'tempfile'
require 'csv'
require 'rest_client'

NUM_BARCODES = 96
num = 0
barcodes = []
while (num < NUM_BARCODES) do
  number = (rand * 999999).floor.to_s
  barcode = ["FR"].concat((6 - number.length).times.map { "0" }).concat([number]).join
  found = Asset.find_by(barcode: barcode)
  unless found
    barcodes.push(barcode)
    num = num + 1
  end
end
puts

letters = ("A".."H").to_a
columns = (1..12).to_a
location_for_position = NUM_BARCODES.times.map do |i|
  "#{letters[(i / columns.length).floor]}#{(columns[i % columns.length]).to_s}"
end

temp_file = Tempfile.new
CSV.open(temp_file, "w") do |csv|
  location_for_position.each_with_index do |location, i|
    csv << [location, barcodes[i]]
  end
end

puts temp_file.read
