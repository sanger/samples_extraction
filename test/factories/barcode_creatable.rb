FactoryBot.define do
  sequence :barcode do |n|
    n
  end

  sequence :barcode_creatable do |n|
    SBCF::SangerBarcode.new(prefix:'FF',number: n).human_barcode
  end
end
