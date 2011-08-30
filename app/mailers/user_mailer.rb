class UserMailer < BaseMailer

  def send_activation(host, to, email, user_id, activation_code)
    @host = host
    subject           = "Please activate your account"
    @email            = email
    @activation_code  = activation_code
    @user_id          = user_id
    mail(:to => to, :subject => subject)
  end

  def send_forgot_password(host, to, email, password)
    @host = host
    subject     = "Your password is ..."
    @email      = email
    @password   = password
    mail(:to => to, :subject => subject)
  end
  
  def send_changed_email(host, to, old_email, new_email)
    @host = host
    subject    = "You have changed your email"
    @old_email  = old_email
    @new_email  = new_email 
    mail(:to => to, :subject => subject)
  end
  
  def send_confirmation(host, to, deal)
    @deal = deal
    @host = host    
    subject   = "Congratulations! Your deal has tipped."
    mail(:to => to, :subject => subject)
  end
  
end
