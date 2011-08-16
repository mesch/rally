Rally::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false
  
  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  # Sendmail setup
  OPTIONS[:action_mailer_deliver_method] = :sendmail
  config.action_mailer.perform_deliveries = true
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false 
  config.serve_static_assets = true

  # Set the default action mailer host..
  OPTIONS[:site_url] = "localhost:3000"
  config.action_mailer.default_url_options = { :host => OPTIONS[:site_url] }

  OPTIONS[:paperclip_storage_options] = {
    :path => ":rails_root/public/system/#{Rails.env}/:class/:attachment/:id/:style.:extension",
    :url => "/system/#{Rails.env}/:class/:attachment/:id/:style.:extension"
  }

  OPTIONS[:paperclip_report_storage_options] = OPTIONS[:paperclip_storage_options].merge(
    { :path => ":rails_root/public/system/#{Rails.env}/:class/:attachment/:id/:basename.:extension",
      :url => "/system/#{Rails.env}/:class/:attachment/:id/:basename.:extension"}
  )

  # Order Timout
  OPTIONS[:order_timeout] = 60
  
  # Facebook logins
  OPTIONS[:facebook_app_id] = "221523644534233"
  OPTIONS[:facebook_api_key] = "d27f5c585be57aa5e8bc0f034ab9b329"
  OPTIONS[:facebook_secret_key] = "fbea89d411fa448c97028147d3141ce4"
  
  OPTIONS[:facebook_app_url] = "http://apps.facebook.com/rc_deals_dev/"
  
  # Used for "some" calls to fb. Really confusing. Not really sure why it works.
  # See http://forum.developers.facebook.net/viewtopic.php?pid=280400#p280400
  # See http://developers.facebook.com/docs/authentication/ Authenticating as an Application
  #OPTIONS[:facebook_application_access_token] = "119734331414282|WB31YAEnMppGm9auGUm2aXGEr9c"
end

