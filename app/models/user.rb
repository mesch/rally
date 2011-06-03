require "digest"

class User < ActiveRecord::Base
  validates_length_of :first_name, :maximum => 50
  validates_length_of :last_name, :maximum => 50
  validates_length_of :email, :maximum => 50
  validates_uniqueness_of :email
  validates_presence_of :email, :salt
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email."

  # info fields
  validates_length_of :first_name, :maximum => 50
  validates_length_of :last_name, :maximum => 50
  validates_length_of :mobile_number, :maximum => 20

  # different validations for password, password_confirmation based on type of action
  validates_length_of :password, :within => 4..40, :on => :create
  validates_confirmation_of :password, :on => :create
  validates_length_of :password, :within => 4..40, :on => :update, :if => :password_required?
  validates_confirmation_of :password, :on => :update, :if => :password_required?
  validates_presence_of :password, :password_confirmation, :on => :update, :if => :password_required?

  attr_protected :id, :salt
  attr_accessor :password, :password_confirmation

  money :balance, :currency => false

  has_many :coupons
  has_many :orders
  has_many :order_payments

  def full_name
    return "#{self.first_name} #{self.last_name}"
  end
  
  def coupon_count(deal_id=nil)
    if deal_id
      return Order.sum(:quantity, :conditions => ["user_id = ? AND deal_id = ?", self.id, deal_id])
    else
      return Order.sum(:quantity, :conditions => ["user_id = ?", self.id])
    end
  end

  # Tries to find an existing unconfirmed order for the deal - else return a new order
  def unconfirmed_order(deal_id)
    if order = Order.find(:first, :conditions => ["user_id = ? AND deal_id = ? AND state = ?", self.id, deal_id, OPTIONS[:order_states][:created]])
      return order
    else
      return Order.new(:user_id => self.id, :deal_id => deal_id)
    end
  end

  # Authentication methods
  def self.authenticate(email, password)
    u = find(:first, :conditions=>["email = ?", email])     
    return nil if u.nil?
    return u if User.encrypt(password, u.salt)==u.hashed_password
    return nil
  end  

  def password=(pass)
    @password=pass
    self.salt = User.random_string(10) if !self.salt?
    self.hashed_password = User.encrypt(@password, self.salt)
  end

  # Mailer methods
  def send_new_password
    new_pass = User.generate_password
    self.password = self.password_confirmation = new_pass
    if self.save
      # Send the user email through a delayed job
      UserMailer.delay.send_forgot_password(self.email, self.email, new_pass)
      return true
    end
    return false
  end
  
  def send_activation
    if self.update_attributes(:activation_code => User.generate_activation_code)
      # Send the user email through a delayed job
      UserMailer.delay.send_activation(self.email, self.email, self.id, self.activation_code)
      return true
    end
    return false
  end

  def send_email_change(old_email)
    # Send the user email through a delayed job
    UserMailer.delay.send_changed_email(old_email, old_email, self.email)
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
    User.secure_digest(Time.now, (1..10).map{ rand.to_s })
  end

  def self.generate_password
    return User.random_string(5)
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
