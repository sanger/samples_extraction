JSONAPI.configure do |config|
  #:underscored_key, :camelized_key, :dasherized_key, or custom
  config.json_key_format = :underscored_key
  config.resource_key_type = :uuid

  # optional request features
  config.allow_include = true

  config.default_page_size = 25
  config.maximum_page_size = 1000
end
