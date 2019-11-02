module Parsers
  module CsvLayout
    module Validators
      class AnyBarcodeValidator < ActiveModel::Validator
        def validate(record)
          if record.barcode.blank?
            record.errors.add(:barcode, "Barcode is empty")
          end
        end
      end
    end
  end
end
