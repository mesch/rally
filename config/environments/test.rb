Rally::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  
  # Set the default action mailer host..
  OPTIONS[:site_url] = "www.rcom.com"
  config.action_mailer.default_url_options = { :host => OPTIONS[:site_url] }
  
  OPTIONS[:paperclip_storage_options] = {
    :path => ":rails_root/public/system/#{Rails.env}/:class/:attachment/:id/:style.:extension",
    :url => "http://www.rcom.com/system/#{Rails.env}/:class/:attachment/:id/:style.:extension"
  }
  
  OPTIONS[:paperclip_report_storage_options] = OPTIONS[:paperclip_storage_options].merge(
    { :path => ":rails_root/public/system/#{Rails.env}/:class/:attachment/:id/:basename.:extension",
      :url => "/system/#{Rails.env}/:class/:attachment/:id/:basename.:extension" }
  )
  
  # Facebook logins - using test accounts
  OPTIONS[:facebook_app_id] = "221523644534233"
  OPTIONS[:facebook_api_key] = "d27f5c585be57aa5e8bc0f034ab9b329"
  OPTIONS[:facebook_secret_key] = "fbea89d411fa448c97028147d3141ce4"
  
  OPTIONS[:facebook_app_url] = "http://apps.facebook.com/rc_deals_dev/"
  
end