Versioneye::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store, Settings.instance.memcache_servers,{
    :username => Settings.instance.memcache_username, :password => Settings.instance.memcache_password,
    :namespace => 'veye', :expires_in => 1.day, :compress => true }

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false

  config.serve_static_assets = true
  config.action_dispatch.x_sendfile_header = nil

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = false

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.css_compressor = :yui
  config.assets.js_compressor = :uglifier
  config.assets.debug = false
  config.assets.compile = true
  config.assets.digest = true

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( application.css application_lp.css *.js )

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # See everything in the log (default is :info)
  config.log_level = :info

  config.i18n.fallbacks = true

  Settings.instance.server_url  = GlobalSetting.default.server_url
  Settings.instance.server_host = GlobalSetting.default.server_host
  Settings.instance.server_port = GlobalSetting.default.server_port

  config.active_support.deprecation = :notify
  config.action_mailer.delivery_method = :smtp
  EmailSettingService.update_action_mailer_from_db
  Settings.instance.smtp_sender_email = EmailSettingService.email_setting.sender_email
  Settings.instance.smtp_sender_name  = EmailSettingService.email_setting.sender_name
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.raise_delivery_errors = true

  routes.default_url_options = { host: Settings.instance.server_host, port: Settings.instance.server_port }

end
