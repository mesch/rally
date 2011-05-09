# :smtp in most modes, :test in test mode 
ActionMailer::Base.delivery_method = OPTIONS[:action_mailer_deliver_method]

# Common settings
ActionMailer::Base.smtp_settings = {
    :address => OPTIONS[:email_address],
    :port => OPTIONS[:email_port],
    :domain => OPTIONS[:email_domain],
    :authentication => OPTIONS[:email_authentication],    
    :user_name => OPTIONS[:email_username],
    :password => OPTIONS[:email_password],
    :enable_starttls_auto => OPTIONS[:enable_starttls_auto]
}