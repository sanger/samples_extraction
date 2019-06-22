source 'http://rubygems.org'



# Service libraries
gem 'puma'
gem 'daemons'
gem 'redis'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'mysql2'

# Rails and framework libraries
gem 'tzinfo-data'
gem 'rails'#, '~> 5.1.4'
gem 'activerecord-session_store'
gem 'micro_token'
gem 'activerecord-import'


# Rails views and UI
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
gem 'rails-assets-tether'#, '>= 1.1.0'
gem 'ace-rails-ap'

# Serializers
gem 'rdf-n3'
gem 'jbuilder'#, '~> 2.0'
gem 'yajl-ruby'#, '>= 1.3'
gem 'google_hash'

# Tools
gem 'sanger_barcode_format', github: 'sanger/sanger_barcode_format'
gem 'pmb-client', git: 'https://github.com/sanger/pmb-client.git'

# Sequencescspae
gem 'rest-client'
gem 'faraday'
gem 'sequencescape-client-api',
  # Should be switched back to sanger + production for deployment
  :github => 'emrojo/sequencescape-client-api',
  :branch  => 'asset-attribute-update-merged-with-rails-4',
  :require => 'sequencescape'


# Debugging
gem 'rb-readline'

# Docs
gem 'sdoc'#, '~> 0.4.0', group: :doc


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
  gem 'rubocop-rails'
end


group :deployment do
  gem 'exception_notification'
  gem 'gmetric', '~>0.1.3'
end
