class UserMailer < BaseMailer

  def send_activation(to, email, user_id, activation_code)
    subject           = "Please activate your account"
    @email            = email
    @activation_code  = activation_code
    @user_id          = user_id
    mail(:to => to, :subject => subject)
  end

  def send_forgot_password(to, email, password)
    subject     = "Your password is ..."
    @email      = email
    @password   = password
    mail(:to => to, :subject => subject)
  end
  
  def send_changed_email(to, old_email, new_email)
    subject    = "You have changed your email"
    @old_email  = old_email
    @new_email  = new_email 
    mail(:to => to, :subject => subject)
  end

end
