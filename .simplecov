# frozen_string_literal: true

SimpleCov.start 'rails' do
  add_filter '/test/'
  add_filter '/coverage/'
  add_filter '/db/'
  add_filter '/log/'
  add_filter '/public/'
  add_filter '/script/'
  add_filter '/vendor/'
  add_filter '/tmp/'

  enable_coverage :branch

  # You can add_filter here to add anything else you don't want to cover
end
