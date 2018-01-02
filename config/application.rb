require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MiradorAnnotationsServer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
     config.time_zone = 'Eastern Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.action_dispatch.default_headers = {
        # Set CORS headers for public access
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Request-Method' => %w{GET POST OPTIONS}.join(","),
        'Access-Control-Allow-Methods' => 'POST, PUT, DELETE, GET, OPTIONS',
        'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Authorization, tgtoken, tgToken, bearer-token',
        'Content-Type' => 'application/json'
    }

    # config.autoload_paths += Dir["#{config.root}/app/models/", "#{config.root}/lib/**/"]
    config.eager_load_paths += %W(#{config.root}/app/models #{config.root}/lib/modules)

    config.iiif_collections_host = ENV['IIIF_COLLECTIONS_HOST']
    config.s3_download_prefix = ENV['S3_PUBLIC_DOWNLOAD_PREFIX']
    config.use_jwt_auth = (ENV['USE_JWT_AUTH'] == 'Y')
  end
end
