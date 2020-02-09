FactoryBot.define do
  sequence :barcode_value do |n|
    n
  end

  sequence :barcode_creatable do |n|
    SBCF::SangerBarcode.new(prefix:'FF',number: n).human_barcode
  end

  sequence :barcode do |n|
    SBCF::SangerBarcode.new(prefix:'DN',number: n).human_barcode
  end

  sequence :plate_barcode do |n|
    SBCF::SangerBarcode.new(prefix:'DN',number: n).human_barcode
  end

  sequence :tube_barcode do |n|
    SBCF::SangerBarcode.new(prefix:'NT',number: n).human_barcode
  end

end
