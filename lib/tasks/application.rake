# frozen_string_literal: true

namespace :application do
  task deploy: ['label_templates:setup']
end
