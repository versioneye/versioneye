require File.expand_path('../boot', __FILE__)

# require 'rails/all' # commented out because of mongodb.

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie"
require 'dalli'
require 'tire'
#require 'will_paginate/mongoid'
# require 'yajl/json_gem'


if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end


class Settings
  json = File.read("config/settings.json")
  resp = ERB.new(json).result
  settings = JSON.parse(resp)
  if settings
    settings[Rails.env].each { |name, value|
      instance_variable_set("@#{name}", value)
      self.class.class_eval { attr_reader name.intern }
    }
  end
end


module Versioneye
  class Application < Rails::Application

    Mongoid.load!("config/mongoid.yml")

    Mongoid.logger.level = Logger::ERROR
    Moped.logger.level = Logger::ERROR

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.2'

    config.assets.initialize_on_precompile = false

    # http://groups.google.com/group/mongoid/browse_thread/thread/df278a11dba4d331?pli=1
    # config.generators do |g|
    #   g.orm :active_record
    # end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/crawlers)
    config.autoload_paths += %W(#{config.root}/app/api/v1)
    config.autoload_paths += Dir["#{config.root}/app/api/**/"]
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

  end
end
