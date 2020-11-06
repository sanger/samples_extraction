# frozen_string_literal: true

require 'warren'

if Rails.application.config.warren.present?
  Warren.setup(Rails.application.config.warren.deep_symbolize_keys.slice(:type, :config))
else
  Rails.logger.warn "Warren.yml not configured for #{ENV['RAILS_ENV']}"
end
