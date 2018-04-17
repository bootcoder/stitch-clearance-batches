require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TakeHomeChallenge
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # NOTE: Didn't HAVE TO mod this but it resolves a warning which I have a hard time not doing...
    # Ensure conversion of old sqlite3 bool to ints
    config.active_record.sqlite3.represent_boolean_as_integer = true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
