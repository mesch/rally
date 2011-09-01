Rally::Application.configure do

  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local = false
  config.action_controller.perform_caching             = true
    
  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Use memcache
  # Rails.configuration.cache_store = :dalli_store

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Set the default action mailer host..
  OPTIONS[:site_url] = "www.rallycommerce.net"
  config.action_mailer.default_url_options = { :host => OPTIONS[:site_url] }
  
  OPTIONS[:paperclip_storage_options] = {
    :storage => :s3,
    :s3_credentials => "#{::Rails.root.to_s}/config/s3.yml",
    :s3_protocol => 'https',
    :path => ":class/:attachment/:id/:style.:extension"
  }
  
  OPTIONS[:paperclip_report_storage_options] = OPTIONS[:paperclip_storage_options].merge(
    { :path => ":class/:attachment/:id/:basename.:extension" }
  )
  
  # Facebook logins
  OPTIONS[:facebook_app_id] = "218320038188280"
  OPTIONS[:facebook_api_key] = "347577002d2940ab5c2842910a19d688"
  OPTIONS[:facebook_secret_key] = "c7ca4cc510a913e03f7fdd6ccb10026e"
  
  OPTIONS[:facebook_app_url] = "http://apps.facebook.com/rc_deals/"
  
end

Rally::Application.config.session_store :cookie_store, :key => '_rally_session', :domain => '.rallycommerce.net'