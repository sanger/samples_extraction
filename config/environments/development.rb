Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Settings specified here will take precedence over those in config/application.rb.

  benchmarking = ENV.fetch('BENCHMARKING', nil) == 'true'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = benchmarking

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  config.allow_concurrency = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.pmb_uri = ENV.fetch('SE_PMB_URI', 'http://localhost:10000/v1')
  config.redis_url = ENV.fetch('SE_REDIS_URI', 'redis://127.0.0.1:6379')
  config.ss_uri = ENV.fetch('SE_SS_URI', 'http://localhost:3000/api/1/')
  config.ss_api_v2_uri = ENV.fetch('SE_SS_API_V2_URI', 'http://localhost:3000')
  config.ss_authorisation = ENV.fetch('SE_SS_API_AUTH', 'development')
  config.searcher_name_by_barcode = 'Find assets by barcode'
  config.searcher_study_by_name = 'Find study by name'
  config.printing_disabled = true
  config.redis_enabled = true

  config.inference_engine = :default
  config.cwm_path = ENV.fetch('CWM_PATH', '')
  config.default_n3_resources_url = 'http://localhost:9200'

  config.enable_reasoning = false

  config.log_level = :warn if benchmarking
end
