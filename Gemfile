source 'http://rubygems.org'


# Service libraries
gem 'sanger_warren' # Wraps bunny and manages connection pools and configuration
gem 'puma'
gem 'daemons'
gem 'redis'
gem 'delayed_job_active_record'
gem 'mysql2'
gem 'bootsnap', require: false

# Rails and framework libraries
gem 'rails', '~> 5.2'
gem 'tzinfo-data'
gem 'activerecord-session_store'
gem 'micro_token'
gem 'activerecord-import'
gem 'aasm'

# Rails views and UI
gem 'turbolinks'
gem 'bootstrap_form'
gem 'sprockets-rails'
gem 'js_cookie_rails'
gem 'webpacker'
gem 'webpacker-react'
gem 'jquery-rails'
gem 'react-rails'
gem 'sass-rails'
gem 'bootstrap-sass'
gem 'will_paginate'
gem 'will_paginate-bootstrap'


# Javascript UI
gem 'ejs'
gem 'dropzonejs-rails'
gem 'rails-assets-tether'
gem 'ace-rails-ap'

# Serializers
gem 'rdf-n3'
gem 'jbuilder'
gem 'oj'

# Traction endpoints
gem 'jsonapi-resources'
gem 'json_api_client'

# Tools
gem 'sanger_barcode_format', git: 'https://github.com/sanger/sanger_barcode_format.git'
gem 'pmb-client', git: 'https://github.com/sanger/pmb-client.git'

# Sequencescspae
gem 'rest-client'
gem 'faraday'
gem 'sequencescape-client-api', require: 'sequencescape'

# Debugging
gem 'rb-readline'

# Docs
gem 'sdoc'#, '~> 0.4.0', group: :doc


group :development, :test do
  # Call 'pry' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'ruby-growl'
end

group :test do
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'rails-controller-testing'
  gem 'database_cleaner'
  gem 'json-schema'
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
  gem 'rubocop-rails'
end


group :deployment do
  gem 'exception_notification'
  gem 'gmetric', '~>0.1.3'
end
