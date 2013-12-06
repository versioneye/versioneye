Versioneye::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true
  config.action_controller.perform_caching = false
  config.cache_store = :dalli_store, Settings.memcache_servers,{
    :username => Settings.memcache_username, :password => Settings.memcache_password,
    :namespace => 'veye', :expires_in => 1.day, :compress => true }

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true
  config.assets.css_compressor = :yui
  config.assets.js_compressor = :uglifier

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  config.assets.precompile += %w( application.css application_lp.css *.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.action_mailer.delivery_method   = :postmark
  config.action_mailer.postmark_settings = { :api_key => Settings.postmark_api_key }

  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #    :address              => ",
  #    :port                 => 587,
  #    :domain               => '',
  #    :user_name            => '',
  #    :password             => '',
  #    :authentication       => '',
  #    :enable_starttls_auto => true  }

  ENV['API_BASE_PATH'] = "https://www.versioneye.com/api"

  Stripe.api_key = Settings.stripe_secret_key

  if Settings.aws_s3_access_key_id && Settings.aws_s3_secret_access_key
      AWS::S3::Base.establish_connection!( :access_key_id => Settings.aws_s3_access_key_id, :secret_access_key => Settings.aws_s3_secret_access_key )
  end
end
