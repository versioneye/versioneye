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

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false

  # See everything in the log (default is :info)
  config.log_level = :info

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( application.css application_lp.css *.js )

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.delivery_method = :smtp
  EmailSettingService.update_action_mailer_from_db
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options   = { :host => 'www.versioneye.com' }

end
