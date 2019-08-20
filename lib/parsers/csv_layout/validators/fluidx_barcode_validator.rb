module Parsers
  module CsvLayout
    module Validators
      class FluidxBarcodeValidator < ActiveModel::Validator
        def validate(record)
          unless valid_fluidx_barcode?(record)
            record.errors.add(:barcode, "Invalid fluidx barcode format #{record.barcode}")
          end
        end

        protected

        def valid_fluidx_barcode?(record)
          record.barcode.start_with?('F')
        end

      end
    end
  end
end
