# Define a common OPTIONS hash unless already defined
OPTIONS = {} unless defined?(OPTIONS)

# Admin basic auth login
OPTIONS[:admin_user_name] = "rally_admin"
OPTIONS[:admin_password] = "pier38"

# Captcha stuff
OPTIONS[:recaptcha_public_key] = "6Lc7G8QSAAAAAIErQb-7rMDJ-2vVL2BbIqKN_fHk"
OPTIONS[:recaptcha_private_key] = "6Lc7G8QSAAAAADTgEYoxR2cG2HbaBUFVwaUEggfn"

# UI stuff
OPTIONS[:site_name] = "Shop and Rally"

# Use the same from address and return-path for all emails
OPTIONS[:email_from] = "Rally Commerce <support@rallycommerce.com>"
OPTIONS[:email_return_path] = "support@rallycommerce.com"

# Internal email info
OPTIONS[:internal_email_to] = "admin@rallycommerce.com"
OPTIONS[:internal_error_to] = "admin@rallycommerce.com"
OPTIONS[:internal_email_from] = "internal@rallycommerce.com"

# Email settings for prod and staging
OPTIONS[:action_mailer_deliver_method] = :smtp
OPTIONS[:email_address] = "smtp.sendgrid.net" 
OPTIONS[:email_port] = "25"
OPTIONS[:email_authentication] = :plain
OPTIONS[:email_username] = ENV['SENDGRID_USERNAME']
OPTIONS[:email_password] = ENV['SENDGRID_PASSWORD']
OPTIONS[:email_domain] = ENV['SENDGRID_PASSWORD']
OPTIONS[:enable_starttls_auto] = false

# Date / Time formatting
OPTIONS[:date_format] = '%m/%d/%y'
OPTIONS[:time_format] = '%Y-%m-%d %H:%M:%S'

# Order Timout
OPTIONS[:order_timeout] = 10*60

# Order States
OPTIONS[:order_states] = {:created => 'CREATED', :authorized => 'AUTHORIZED', :paid => 'PAID'}

# Order Payment Gateways
OPTIONS[:gateways] = {:authorize_net  => 'AUTHORIZE_NET'}

# Paperclip defaults
OPTIONS[:logo_default_url] = '/images/logo_:style.gif'
OPTIONS[:deal_image_default_url] = '/images/missing_deal_image.gif'
