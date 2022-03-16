module Parsers
  module CsvLayout
    module Validators
      class LocationValidator < ActiveModel::Validator
        def validate(record)
          unless valid_location?(record)
            record.errors.add(:location, "Invalid location")
          end
        end

        protected

        def valid_location?(record)
          record.location.present? && record.location.match?(TokenUtil::LOCATION_REGEXP)
        end
      end
    end
  end
end
