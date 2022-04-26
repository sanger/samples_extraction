# @todo Migrate to StepPlanner https://github.com/sanger/samples_extraction/issues/193

require 'tempfile'
require 'csv'
require 'rest_client'

NUM_BARCODES = 96
num = 0
barcodes = []
while (num < NUM_BARCODES) do
  number = (rand * 999999).floor.to_s
  barcode = ["FR"].concat(Array.new((6 - number.length)) { "0" }).concat([number]).join
  found = Asset.find_by(barcode: barcode)
  unless found
    barcodes.push(barcode)
    num = num + 1
  end
end
puts

letters = ("A".."H").to_a
columns = (1..12).to_a
location_for_position = Array.new(NUM_BARCODES) do |i|
  "#{letters[(i / columns.length).floor]}#{columns[i % columns.length]}"
end

temp_file = Tempfile.new
CSV.open(temp_file, "w") do |csv|
  location_for_position.each_with_index do |location, i|
    csv << [location, barcodes[i]]
  end
end

file = UploadedFile.create(filename: "_temp.csv", data: temp_file.read)
asset = file.build_asset(content_type: "csv")

data = { add_assets: [[nil, [asset.uuid]]] }

puts data.to_json
