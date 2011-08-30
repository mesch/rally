require "digest"
require "subdomain"

class User < ActiveRecord::Base
  validates_length_of :first_name, :maximum => 50
  validates_length_of :last_name, :maximum => 50
  validates_length_of :email, :maximum => 50
  validates_uniqueness_of :email, :message => "That email has already been taken. Login if you already have an account"
  validates_presence_of :email, :salt
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "Invalid email"

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
  
  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ['email like ?', "%#{search}%"],
             :order => 'created_at desc'
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
    if order = Order.find(:first, :conditions => ["user_id = ? AND deal_id = ? AND state = ?", self.id, deal_id, Order::CREATED])
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
  
  def email=(email)
    if email
      email = email.downcase
    end
    self[:email] = email
  end

  # Mailer methods
  def send_new_password(host)
    new_pass = User.generate_password
    self.password = self.password_confirmation = new_pass
    if self.save
      # Send the user email through a delayed job
      UserMailer.delay.send_forgot_password(host, self.email, self.email, new_pass)
      return true
    end
    return false
  end
  
  def send_activation(host)
    if self.update_attributes(:activation_code => User.generate_activation_code)
      # Send the user email through a delayed job
      UserMailer.delay.send_activation(host, self.email, self.email, self.id, self.activation_code)
      return true
    end
    return false
  end

  def send_email_change(host, old_email)
    # Send the user email through a delayed job
    UserMailer.delay.send_changed_email(host, old_email, old_email, self.email)
    return true
  end

  def update_email(host, new_email)
    old_email = self.email
    if self.update_attributes(:email => new_email, :activated => false)
      if self.send_activation(host) and self.send_email_change(host, old_email)
        return true
      end
    end
    return false
  end
  
  def send_confirmation(deal_id)
    deal = Deal.find_by_id(deal_id)
    if deal
      merchant = Merchant.find_by_id(deal.merchant_id)
      host = OPTIONS[:site_url]
      if merchant.merchant_subdomain
        host = new_host_subdomain(host, 'www', merchant.merchant_subdomain.subdomain)
      end
      UserMailer.delay.send_confirmation(host, self.email, deal)
      return true
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
