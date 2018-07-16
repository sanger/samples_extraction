require 'barcode'

FactoryBot.define do
  sequence :barcode do |n|
    n
  end

  sequence :barcode_creatable do |n|
  	Barcode.calculate_sanger_human_barcode("FF", n).to_s
  end
end