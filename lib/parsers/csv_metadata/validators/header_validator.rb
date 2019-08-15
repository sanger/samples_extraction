module Parsers
  module CsvMetadata
    module Validators
      class HeaderValidator < ActiveModel::Validator
        def validate(record)
          record.headers.each_with_index do |header, index|
            if header.empty?
              record.errors.add(:header, "Header #{index} is empty")
            end
          end
        end
      end
    end
  end
end
