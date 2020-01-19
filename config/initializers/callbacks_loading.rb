#
# Initialization of actions to perform when some properties are added or removed.
#
require 'fact_changes'
require 'callback'
Dir[Rails.root.join('lib/callbacks/*.rb')].each { |f| require f }
Dir[Rails.root.join('lib/callbacks/**/*.rb')].each { |f| require f }
