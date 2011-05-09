require "digest"
class Merchant < ActiveRecord::Base
  
  validates_length_of :username, :within => 3..40
  validates_length_of :name, :maximum => 50
  validates_length_of :email, :maximum => 50  
  validates_uniqueness_of :username
  validates_presence_of :name, :username, :email, :salt, :time_zone
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email."

  # different validations for password, password_confirmation based on type of action
  validates_length_of :password, :within => 4..40, :on => :create
  validates_confirmation_of :password, :on => :create
  validates_length_of :password, :within => 4..40, :on => :update, :if => :password_required?
  validates_confirmation_of :password, :on => :update, :if => :password_required?
  validates_presence_of :password, :password_confirmation, :on => :update, :if => :password_required?

  attr_protected :id, :salt
  attr_accessor :password, :password_confirmation
  
  # Authentication methods
  def self.authenticate(username, password)
    m=find(:first, :conditions=>["username = ?", username])
    return nil if m.nil?
    return m if Merchant.encrypt(password, m.salt)==m.hashed_password
    nil
  end  

  def password=(pass)
    @password=pass
    self.salt = Merchant.random_string(10) if !self.salt?
    self.hashed_password = Merchant.encrypt(@password, self.salt)
  end

  # Mailer methods
  def send_new_password
    new_pass = Merchant.random_string(5)
    self.password = self.password_confirmation = new_pass
    if self.save
      # Send the client email through a delayed job
      MerchantMailer.delay.send_forgot_password(self.email, self.username, new_pass)
      return true
    end
    return false
  end
  
  def send_activation
    if self.update_attributes(:activation_code => Merchant.generate_activation_code)
      # Send the client email through a delayed job
      MerchantMailer.delay.send_activation(self.email, self.username, self.id, self.activation_code)
      return true
    end
    return false
  end
  
  def send_email_change(old_email)
    # Send the client email through a delayed job
    MerchantMailer.delay.send_changed_email(old_email, self.username, old_email, self.email)
    return true
  end
  
  def update_email(new_email)
    old_email = self.email
    if self.update_attributes(:email => new_email, :activated => false)
      if self.send_activation and self.send_email_change(old_email)
        return true
      end
    end
    return false
  end
  
  # Activation methods
  def activate
    return self.update_attributes(:activated => true)
  end
  
  def inactivate
    return self.update_attributes(:activated => false)
  end

  # code generators
  def self.generate_activation_code
    Merchant.secure_digest(Time.now, (1..10).map{ rand.to_s })
  end

  def self.generate_api_key
    Merchant.secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
  
  protected

  def password_required?
    !password.blank?
  end
  
  def self.secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end
   
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest(password+salt)
  end

  def self.random_string(len)
    #generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end  
  
end
