require "digest"
class Merchant < ActiveRecord::Base
  # coupon types
  COUPON_CODE = 'COUPON_CODE'
  COUPON_URL = 'COUPON_URL'

  validates_length_of :username, :within => 3..40
  validates_length_of :name, :maximum => 50
  validates_length_of :email, :maximum => 50  
  validates_uniqueness_of :username
  validates_presence_of :name, :username, :email, :salt, :time_zone
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "invalid email"
  validates_inclusion_of :redemption_type, :in => [ COUPON_CODE, COUPON_URL ]

  # info fields
  validates_length_of :website, :maximum => 255
  validates_length_of :contact_name, :maximum => 255
  validates_length_of :address1, :maximum => 255
  validates_length_of :address2, :maximum => 255
  validates_length_of :city, :maximum => 255
  validates_length_of :state, :maximum => 255
  validates_length_of :zip, :maximum => 255
  validates_length_of :country, :maximum => 255
  validates_length_of :phone_number, :maximum => 255
  validates_length_of :bank, :maximum => 255
  validates_length_of :account_name, :maximum => 255
  validates_length_of :routing_number, :maximum => 255
  validates_length_of :account_number, :maximum => 255
  validates_length_of :paypal_account, :maximum => 255

  # different validations for password, password_confirmation based on type of action
  validates_length_of :password, :within => 4..40, :on => :create
  validates_confirmation_of :password, :on => :create
  validates_length_of :password, :within => 4..40, :on => :update, :if => :password_required?
  validates_confirmation_of :password, :on => :update, :if => :password_required?
  validates_presence_of :password, :password_confirmation, :on => :update, :if => :password_required?

  # logo
  MAX_IMAGE_SIZE = 1048576 # Max bytes (1 MB)
  CONTENT_TYPES = ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/bmp']
  LOGO_SIZE = "400x100>"
  FOOTER_SIZE = "150x40>"

  #validates_attachment_presence :logo
  validates_attachment_size :logo, :less_than => MAX_IMAGE_SIZE, :if => lambda { logo.dirty? }
  validates_attachment_content_type :logo, :content_type => CONTENT_TYPES, :if => lambda { logo.dirty? }
  
  has_attached_file :logo, {
    :styles => { 
        :header => LOGO_SIZE, 
        :footer => FOOTER_SIZE 
    },
    :default_url => OPTIONS[:logo_default_url]
  }.merge(OPTIONS[:paperclip_storage_options])

  attr_protected :id, :salt
  attr_accessor :password, :password_confirmation
  
  has_many :deals
  has_one :merchant_subdomain
  has_many :merchant_reports
  
  # Logo methods
  def get_logo
    if self.logo
      return self.logo.url(:header)
    end
    return nil
  end
  
  def get_logo_footer
    if self.logo
      return self.logo.url(:footer)
    end
    return nil
  end
  
  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ['name like ?', "%#{search}%"],
             :order => 'created_at desc'
  end
  
  # Deal methods
  def deals_in_date_range(start_date, end_date)
    return Deal.find(:all,
      :conditions => ["merchant_id = ? AND start_date <= ? AND end_date >= ?", self.id, end_date.beginning_of_day, start_date.end_of_day],
      :order => 'active desc, created_at desc')
  end
  
  def drafts
    return Deal.find(:all, 
      :conditions => ["merchant_id = ? AND published = ? AND active = ?", self.id, false, true], 
      :order => 'active desc, created_at desc')
  end
  
  def current_deals
    return Deal.find(:all, 
      :conditions => ["merchant_id = ? AND published = ? AND end_date >= ? AND active = ?", self.id, true, Time.zone.now, true], 
      :order => 'active desc, created_at desc')
  end
  
  def good_deals
    deals = Deal.find(:all, 
      :conditions => ["merchant_id = ? AND published = ? AND end_date < ? AND active = ?", self.id, true, Time.zone.now, true], 
      :order => 'active desc, created_at desc')
    results = []
    for deal in deals
      if deal.is_tipped
        results << deal
      end
    end
    return results
  end
  
  def failed_deals
    deals = Deal.find(:all, 
      :conditions => ["merchant_id = ? AND published = ? AND end_date < ? AND active = ?", self.id, true, Time.zone.now, true], 
      :order => 'active desc, created_at desc')
    results = []
    for deal in deals
      if !deal.is_tipped
        results << deal
      end
    end
    return results
  end
  
  # Authentication methods
  def self.authenticate(username, password)
    m = Merchant.find_by_username(username)
    return nil if m.nil?
    return m if Merchant.encrypt(password, m.salt)==m.hashed_password
    nil
  end  

  def password=(pass)
    @password=pass
    self.salt = Merchant.random_string(10) if !self.salt?
    self.hashed_password = Merchant.encrypt(@password, self.salt)
  end

  def website=(website)
    if website and !website.match(/^http(s)?:\/\//)
      website = "http://" + website
    end
    self[:website] = website
  end
  
  def username=(username)
    if username
      username = username.downcase
    end
    self[:username] = username
  end

  # Mailer methods
  def send_new_password
    new_pass = Merchant.random_string(5)
    self.password = self.password_confirmation = new_pass
    if self.save
      # Send the merchant email through a delayed job
      MerchantMailer.delay.send_forgot_password(self.email, self.username, new_pass)
      return true
    end
    return false
  end
  
  def send_activation
    if self.update_attributes(:activation_code => Merchant.generate_activation_code)
      # Send the merchant email through a delayed job
      MerchantMailer.delay.send_activation(self.email, self.username, self.id, self.activation_code)
      return true
    end
    return false
  end
  
  def send_email_change(old_email)
    # Send the merchant email through a delayed job
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
