source 'http://rubygems.org'

gem 'rdf-n3'
gem 'tzinfo-data'
gem 'puma'
gem 'ejs'
gem 'dropzonejs-rails'
gem 'rest-client'
gem 'rails-assets-tether', '>= 1.1.0'
gem 'bootstrap_form'
gem 'sprockets-rails'
gem 'ace-rails-ap'
gem 'daemons'
gem 'yajl-ruby'#, '>= 1.3'

gem 'rb-readline'

gem 'rails'#, '~> 5.1.4'
gem 'activerecord-session_store'

gem 'js_cookie_rails'

gem 'redis'
gem 'micro_token'

gem 'barby'

gem 'webpacker'
gem 'webpacker-react'
gem 'jquery-rails'
gem 'react-rails'

gem 'delayed_job'
gem 'delayed_job_active_record'

#gem 'sequencescape-client-api'
gem 'sequencescape-client-api',
  # Should be switched back to sanger + production for deployment
  :github => 'emrojo/sequencescape-client-api',
  :branch  => 'asset-attribute-update-merged-with-rails-4',
  :require => 'sequencescape'


# The client api is not good at all
gem 'faraday'

# Bulk insert
gem 'activerecord-import'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
#gem 'rails', '>= 5.1'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.13'
#gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'will_paginate-bootstrap'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc'#, '~> 0.4.0', group: :doc


# Library to convert barcodes in EAN13 and Sanger human barcodes format
gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format'

# Add simple support for print-my barcode)
gem 'pmb-client', git: 'https://github.com/sanger/pmb-client.git'


gem 'google_hash'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'factory_bot_rails'
  gem 'pry'
  gem 'ruby-growl'
end

group :test do
  gem 'factory_bot'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
  gem 'database_cleaner'
end

group :test do
  gem 'launchy'
  gem 'rack_session_access'
end


group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'#, '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'rubocop', require: false
  gem 'rubocop-performance'
end


group :deployment do
  gem 'exception_notification'
  gem 'gmetric', '~>0.1.3'
end
