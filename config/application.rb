require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module PatentManagement
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments/, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Time zone
    config.time_zone = 'Seoul'

    # Locale
    config.i18n.default_locale = :ko
    config.i18n.available_locales = [:ko, :en]

    # ActiveJob
    config.active_job.queue_adapter = :sidekiq

    # CORS
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head]
      end
    end

    # API settings
    config.api_only = false

    # Force SSL in production
    config.force_ssl = Rails.env.production?
  end
end