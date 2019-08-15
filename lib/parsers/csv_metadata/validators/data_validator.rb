module Parsers
  module CsvMetadata
    module Validators
      class DataValidator < ActiveModel::Validator
        def validate(record)
          record.data.keys.each do |header|
            #validator = record.parser.validator_for(header)
            true
          end
        end
      end
    end
  end
end
