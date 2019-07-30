module Parsers
  module CsvLayout
    module Validators
      class LocationValidator < ActiveModel::Validator

        LOCATION_REGEXP = /^([A-H])(\d{1,2})$/

        def validate(record)
          unless valid_location?(record)
            record.errors.add(:location, "Invalid location")
          end
        end

        protected
        def valid_location?(record)
          !record.location.nil? && !!record.location.match(self.class::LOCATION_REGEXP)
        end
      end
    end
  end
end
