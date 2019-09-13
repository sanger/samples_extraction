Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true

  config.action_cable.allowed_request_origins = [%r{https?://\S+}]

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :notify

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  config.allow_concurrency = true
  config.redis_enabled = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new
  config.log_level = :info
  config.log_tags = [:request_id]
  config.time_zone = 'London'
  config.eager_load = true


  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.pmb_uri = ENV.fetch('PMB_URI', '')
  config.ss_uri =  ENV.fetch('SS_URI', '')
  config.ss_api_v2_uri = ENV.fetch('SS_API_V2_URI', '')

  config.ss_authorisation = ENV.fetch('SS_AUTHORISATION_TOKEN', '')
  config.searcher_name_by_barcode = 'Find assets by barcode'

  config.searcher_name_by_barcode = 'Find assets by barcode'
  config.printing_enabled = ENV.fetch('PRINTING_ENABLED', '')=='true'
  config.printing_disabled = !config.printing_enabled

  config.inference_engine = :default
  config.cwm_path = ENV.fetch('CWM_PATH', '')
  config.default_n3_resources_url = ENV.fetch('N3_RESOURCES_URL', '')

  config.enable_reasoning = true

end
