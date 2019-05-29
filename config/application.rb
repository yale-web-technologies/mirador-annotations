require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MiradorAnnotationsServer
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_dispatch.default_headers = {
        # Set CORS headers for public access
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(","),
        'Access-Control-Allow-Methods' => 'POST, PUT, DELETE, GET, OPTIONS',
        'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Authorization, tgtoken, tgToken, bearer-token',
        'Content-Type' => 'application/json'
    }

    config.autoload_paths += Dir["#{config.root}/app/models/", "#{config.root}/lib/**/"]

    config.iiif_collections_host = ENV['IIIF_COLLECTIONS_HOST']
    config.s3_download_prefix = ENV['S3_PUBLIC_DOWNLOAD_PREFIX']
  end
end
