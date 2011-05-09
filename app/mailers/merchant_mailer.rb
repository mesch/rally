class MerchantMailer < BaseMailer

  def send_activation(to, username, merchant_id, activation_code)
    subject    = "Please activate your account"
    @username   = username
    @activation_code = activation_code
    @merchant_id = merchant_id
    mail(:to => to, :subject => subject)
  end

  def send_forgot_password(to, username, password)
    subject    = "Your password is ..."
    @username   = username
    @password   = password
    mail(:to => to, :subject => subject)
  end
  
  def send_changed_email(to, username, old_email, new_email)
    subject    = "You have changed your email"
    @username   = username
    @old_email  = old_email
    @new_email  = new_email 
    mail(:to => to, :subject => subject)
  end

end
