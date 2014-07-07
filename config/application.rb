require File.expand_path('../boot', __FILE__)

require "versioneye-core"

require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "rails/test_unit/railtie"
require "sprockets/railtie" # MongoID # Uncomment this line for Rails 3.1+

require 'dalli'
require 'tire'


if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test enterprise))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end


module Versioneye
  class Application < Rails::Application

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
    config.autoload_paths += %W(#{config.root}/constraints)
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

    begin
      p "application.rb ... instantiate VersioneyeCore ... "
      VersioneyeCore.new
    rescue => e
      p e.message
      p e.backtrace.join("\n")
    end

    AWS.config(
      :s3_endpoint => Settings.instance.aws_s3_endpoint,
      :s3_port => Settings.instance.aws_s3_port,
      :use_ssl => Settings.instance.aws_use_ssl,
      :access_key_id => Settings.instance.aws_access_key_id,
      :secret_access_key => Settings.instance.aws_secret_access_key )

    Product.send        :include, WillPaginateMongoid::MongoidPaginator
    BitbucketRepo.send  :include, WillPaginateMongoid::MongoidPaginator
    GithubRepo.send     :include, WillPaginateMongoid::MongoidPaginator
    Dependency.send     :include, WillPaginateMongoid::MongoidPaginator
    ErrorMessage.send   :include, WillPaginateMongoid::MongoidPaginator
    SubmittedUrl.send   :include, WillPaginateMongoid::MongoidPaginator
    User.send           :include, WillPaginateMongoid::MongoidPaginator
    Versioncomment.send :include, WillPaginateMongoid::MongoidPaginator

    PDFKit.configure do |config|
      config.default_options[:ignore_load_errors] = true
    end

  end
end
