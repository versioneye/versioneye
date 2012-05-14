require File.expand_path('../boot', __FILE__)

# require 'rails/all'

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"


if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  # Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  Bundler.require(:default, :assets, Rails.env)
end

module Versioneye
  class Application < Rails::Application
    
    if Rails.env == 'development'
      configatron.server_url = 'http://localhost:3000'
      configatron.s3_projects_bucket = 'veye_dev_projects'
    elsif Rails.env == 'test'
      configatron.server_url = 'http://versioneye-beta.com'
      configatron.s3_projects_bucket = 'veye_test_projects'
    elsif Rails.env == 'production'
      configatron.server_url = 'http://versioneye.com'
      configatron.s3_projects_bucket = 'veye_prod_projects'
    end
    
    # http://groups.google.com/group/mongoid/browse_thread/thread/df278a11dba4d331?pli=1
    # config.generators do |g| 
    #   g.orm :active_record 
    # end
    
    Mongoid.load!("config/mongoid.yml")
    
    config.action_mailer.delivery_method   = :postmark
    config.action_mailer.postmark_settings = { :api_key => "f6312dfd-6ef7-406c-9a7b-748586a43371" }
    
    AWS::S3::Base.establish_connection!(
          :access_key_id     => 'AKIAJJVCE2X6JF4UGT3Q',
          :secret_access_key => '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'
        )
    
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :en

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.1'

    config.assets.initialize_on_precompile = false
    
    # http://www.edgerails.info/articles/what-s-new-in-edge-rails/2011/04/21/activerecord-identity-map/index.html
    # config.active_record.identity_map = true    
    
  end
end