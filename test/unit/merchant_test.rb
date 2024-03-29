require 'test_helper'

class MerchantTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :merchants

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def equal? (m1, m2, columns=[])
    for column in columns
      if m1[column] != m2[column]
        return false
      end
    end
    return true
  end

  def test_auth 
    #check that we can login with a valid merchant
    assert_equal  @bob, Merchant.authenticate("bob", "test")    
    #wrong username
    assert_nil    Merchant.authenticate("nonbob", "test")
    #wrong password
    assert_nil    Merchant.authenticate("bob", "wrongpass")
    #wrong username and pass
    assert_nil    Merchant.authenticate("nonbob", "wrongpass")
  end

  def test_passwordchange
    # check success
    assert_equal @longbob, Merchant.authenticate("longbob", "longtest")
    #change password
    @longbob.password = @longbob.password_confirmation = "nonbobpasswd"
    assert @longbob.save
    #new password works
    assert_equal @longbob, Merchant.authenticate("longbob", "nonbobpasswd")
    #old pasword doesn't work anymore
    assert_nil   Merchant.authenticate("longbob", "longtest")
    #change back again
    @longbob.password = @longbob.password_confirmation = "longtest"
    assert @longbob.save
    assert_equal @longbob, Merchant.authenticate("longbob", "longtest")
    assert_nil   Merchant.authenticate("longbob", "nonbobpasswd")
  end

  def test_disallowed_passwords
    #check thaat we can't create a merchant with any of the disallowed paswords
    m = Merchant.new(:name => "test", :username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    #too short
    m.password = m.password_confirmation = "wee" 
    assert !m.save     
    assert m.errors['password'].any?
    #too long
    m.password = m.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !m.save     
    assert m.errors['password'].any?
    #empty
    m.password = m.password_confirmation = ""
    assert !m.save    
    assert m.errors['password'].any?
    #ok
    m.password = m.password_confirmation = "bobs_secure_password"
    assert m.save
    assert m.errors.empty? 
  end

  def test_bad_fields
    #check we cant create a merchant with an invalid username
    m = Merchant.new(:name => "test", :username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    m.password = m.password_confirmation = "bobs_secure_password"
    #too short
    m.username = "x"
    assert !m.save     
    assert m.errors['username'].any?
    #too long
    m.username = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebob"
    assert !m.save     
    assert m.errors['username'].any?
    #empty
    m.username = ""
    assert !m.save
    assert m.errors['username'].any?
    #ok
    m.username = "okbob"
    assert m.save
    assert m.errors.empty?
    #no email
    m.email=nil   
    assert !m.save     
    assert m.errors['email'].any?
    #invalid email
    m.email='notavalidemail'   
    assert !m.save     
    assert m.errors['email'].any?
    #ok
    m.email="validtest@abc.com"
    assert m.save  
    assert m.errors.empty?
  end

  def test_collision
    #check can't create new user with existing username
    m = Merchant.new(:name => "existingbob", :username => "existingbob", :email => "test@abc.com")
    m.password = m.password_confirmation = "bobs_secure_password"
    assert !m.save
  end
  
  def test_case_sensitivity
    m1 = Merchant.new(:name => "test", :username => "test", :email => "test@abc.com")
    m1.password = m1.password_confirmation = "lower"
    assert m1.save
    m2 = Merchant.new(:name => "test", :username => "Test", :email => "test@abc.com")
    m2.password = m2.password_confirmation = "upper"
    assert !m2.save
  end

  def test_create
    #check create works and we can authenticate after creation
    m = Merchant.new(:name => "test", :username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    m.password = m.password_confirmation = "bobs_secure_password"
    assert_not_nil m.salt
    assert m.active
    assert_equal m.time_zone, "Pacific Time (US & Canada)"
    assert !m.verisign_trusted
    assert_equal m.redemption_type, Merchant::COUPON_CODE
    assert m.save
    assert_equal 10, m.salt.length
    assert !m.terms
    assert !m.activated
    assert_equal m, Merchant.authenticate(m.username, m.password)

    m = Merchant.new(:name => "test", :username => "newbob", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword")
    assert_not_nil m.salt
    assert_not_nil m.password
    assert_not_nil m.hashed_password
    assert m.save
    assert_equal m, Merchant.authenticate(m.username, m.password)
  end

  def test_create_complete
    #check that we can create with all fields
    #note - this may get out of sync if new fields are added   
    m = Merchant.new(:name => "test", :username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234",
    :logo_file_name => 'logo.png', :logo_content_type => 'image/png', :logo_file_size => 1000,
    :time_zone => "Pacific Time (US & Canada)", :website => "http://abc.com", :contact_name => "Bobby Smith",
    :address1 => "Pier 38", :address2 => "Suite 201", :city => "San Francisco", :state => "CA", :zip => "94103", :country => "USA",
    :phone_number => "4155551212", :tax_id => "123456789", :bank => "BofA", :account_name => "Bob Smith",
    :routing_number => "2345", :account_number => "345a", :paypal_account => "bob@abc.com", 
    :verisign_trusted => 1, :redemption_type => Merchant::COUPON_URL)
    m.password = m.password_confirmation = "bobs_secure_password"
    assert_not_nil m.salt
    assert m.active
    assert m.save
    assert_equal 10, m.salt.length
    assert equal?(m, Merchant.authenticate(m.username, m.password), 
      [:name, :username, :email, :hashed_password, :salt, :logo_file_name, :logo_content_type, :logo_file_size,
        :activation_code, :activate, :time_zone, :website, :contact_name,
        :address1, :address2, :city, :state, :zip, :country, :phone_number, :tax_id, :bank, :account_name,
        :routing_number, :account_number, :paypal_account, :verisign_trusted, :redemption_type])
    #check that changing a local field fails match
    m.contact_name = "Bob Smith"
    assert !equal?(m, Merchant.authenticate(m.username, m.password), 
      [:name, :username, :email, :hashed_password, :salt, :logo_file_name, :logo_content_type, :logo_file_size,
        :activation_code, :activate, :time_zone, :website, :contact_name,
        :address1, :address2, :city, :state, :zip, :country, :phone_number, :tax_id, :bank, :account_name,
        :routing_number, :account_number, :paypal_account, :verisign_trusted, :redemption_type])
  end
  
  
  def test_website
    # empty website - ok
    m = Merchant.new(:name => "test", :username => "newbob", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword")
    assert m.save
    assert_nil m.website
    # adds http if not there
    m = Merchant.new(:name => "test", :username => "newbob1", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword", :website => "www.abc.com")
    assert m.save
    assert_equal m.website, "http://www.abc.com"
    # ignore if http is there
    m = Merchant.new(:name => "test", :username => "newbob2", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword", :website => "http://www.abc.com")
    assert m.save
    assert_equal m.website, "http://www.abc.com"
    # ignore if https is there too
    m = Merchant.new(:name => "test", :username => "newbob3", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword", :website => "https://www.abc.com")
    assert m.save
    assert_equal m.website, "https://www.abc.com"
    
    # also works on updates
    m = Merchant.new(:name => "test", :username => "newbob4", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword", :website => "www.abc.com")
    assert m.save
    assert m.update_attributes(:website => "www.abcd.com")
    assert_equal m.website, "http://www.abcd.com"
    assert m.update_attributes(:website => "http://www.abcd.com")
    assert_equal m.website, "http://www.abcd.com"
    assert m.update_attributes(:website => "https://www.abcd.com")
    assert_equal m.website, "https://www.abcd.com"
  end

  def test_send_activation
    activation_code = @inactivated.activation_code
    assert @inactivated.send_activation
    assert_equal ActionMailer::Base.deliveries.size, 1
    assert_not_equal activation_code, @inactivated.activation_code
  end
  
  def test_send_new_password
    #check user authenticates
    assert_equal  @bob, Merchant.authenticate(@bob.username, "test")    
    #send new password
    assert @bob.send_new_password
    assert_equal ActionMailer::Base.deliveries.size, 1
    #old password no longer works
    assert_nil Merchant.authenticate(@bob.username, "test")
  end
  
  def test_send_email_change
    assert @bob.send_email_change("old_email@rallycommerce.com")
    assert_equal ActionMailer::Base.deliveries.size, 1
  end
  
  def test_update_email
    old_email = @bob.email
    assert @bob.update_email("new_email@rallycommerce.com")
    assert_not_equal old_email, @bob.email
    assert_equal ActionMailer::Base.deliveries.size, 2    
  end

  def test_rand_str
    new_pass = Merchant.random_string(10)
    assert_not_nil new_pass
    assert_equal 10, new_pass.length
  end

  def test_sha1
    m = Merchant.new
    m.name = "test"
    m.username = "nonexistingbob"
    m.email = "test@abc.com"
    m.activation_code = "1234"
    m.salt = "1000"
    m.password = m.password_confirmation = "bobs_secure_password"
    assert m.save
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', m.hashed_password
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', Merchant.encrypt("bobs_secure_password", "1000")
  end

  def test_protected_attributes
    #check attributes are protected
    m = Merchant.new(:id=>999999, :name => "test", :salt=>"I-want-to-set-my-salt", :username => "badbob", :email => "test@abc.com", 
      :activation_code => "1234", :password => "newpassword", :password_confirmation => "newpassword")
    assert m.save
    assert_not_equal 999999, m.id
    assert_not_equal "I-want-to-set-my-salt", m.salt

    m.update_attributes(:id=>999999, :salt=>"I-want-to-set-my-salt", :username => "verybadbob")
    assert m.save
    assert_not_equal 999999, m.id
    assert_not_equal "I-want-to-set-my-salt", m.salt
    assert_equal "verybadbob", m.username
  end
  
  def test_activate
    assert !@inactivated.activated
    m = Merchant.find(@inactivated.id)
    assert m.activate
    assert m.activated
    assert equal?(m, @inactivated, [:name, :username, :hashed_password, :email, :salt, :activation_code, :active])
  end
  
  def test_inactivate
    assert @bob.activated
    m = Merchant.find(@bob.id)
    assert m.inactivate
    assert !m.activated
    assert equal?(m, @bob, [:name, :username, :hashed_password, :salt, :email, :activation_code, :active])
  end
  
  def test_update_email
    m = Merchant.find(@bob.id)
    # bad format
    assert !m.update_email("bad_format")
    m = Merchant.find(@bob.id)
    assert m.activated
    assert equal?(m, @bob, [:name, :username, :email, :hashed_password, :salt, :active, :activation_code, :activated])
    # success
    assert m.update_email("test@abc.com")
    assert_equal m.email, "test@abc.com"
    assert !m.activated
    assert equal?(m, @bob, [:name, :username, :hashed_password, :salt, :active])
  end
  
  def test_get_logo
    #assuming @bob has logo set
    m = Merchant.find(@bob.id)
    assert_equal m.get_logo, m.logo.url(:header)
    assert_equal m.get_logo_footer, m.logo.url(:footer)
    #merchant from scratch uses default logo
    m = Merchant.new(:name => "test", :username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    m.password = m.password_confirmation = "bobs_secure_password"
    assert m.save
    assert_equal m.get_logo, OPTIONS[:logo_default_url].sub(':style', 'header')
    assert_equal m.get_logo_footer, OPTIONS[:logo_default_url].sub(':style', 'footer')
  end
  
  def test_deals_in_date_range
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal m.deals_in_date_range(Time.zone.today, Time.zone.today).size, 1
    assert_equal m.deals_in_date_range(Time.zone.today - 1.days, Time.zone.today).size, 1
    assert_equal m.deals_in_date_range(Time.zone.today, Time.zone.today + 1.days).size, 1
    assert_equal m.deals_in_date_range(Time.zone.today - 1.days, Time.zone.today - 1.days).size, 0
    assert_equal m.deals_in_date_range(Time.zone.today + 1.days, Time.zone.today + 1.days).size, 0
    # multiple deals
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal m.deals_in_date_range(Time.zone.today, Time.zone.today).size, 2
    # delete - still show up
    assert d.delete
    assert_equal m.deals_in_date_range(Time.zone.today, Time.zone.today).size, 2          
  end
  
  def test_drafts
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.drafts().size, 1
    d.update_attributes(:start_date => Time.zone.today - 1.days, :end_date => Time.zone.today)
    assert_equal m.drafts().size, 1    
    d.update_attributes(:start_date => Time.zone.today, :end_date => Time.zone.today + 1.days)
    assert_equal m.drafts().size, 1    
    d.update_attributes(:start_date => Time.zone.today - 1.days, :end_date => Time.zone.today - 1.days)
    assert_equal m.drafts().size, 1    
    d.update_attributes(:start_date => Time.zone.today + 1.days, :end_date => Time.zone.today + 1.days)
    assert_equal m.drafts().size, 1    
    # publish
    d.publish
    assert_equal m.drafts().size, 0   
    # add a draft 
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal m.drafts().size, 1
    # add another draft
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal m.drafts().size, 2
    # delete a draft
    assert d.delete
    assert_equal m.drafts().size, 1  
  end
  
  def test_current_deals
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.current_deals().size, 0
    # publish
    d.publish
    assert_equal m.current_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day)
    assert_equal m.current_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.current_deals().size, 1  
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day - 1.days)
    assert_equal m.current_deals().size, 0
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day + 1.days, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.current_deals().size, 1   
    # add a draft 
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.current_deals().size, 1
    # publish
    assert d.publish
    assert_equal m.current_deals().size, 2
    # delete
    assert d.delete
    assert_equal m.current_deals().size, 1    
  end
  
  def test_good_deals
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day - 1.days, 
      :end_date => Time.zone.today.end_of_day - 1.days, :expiration_date => Time.zone.today.end_of_day, 
      :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.good_deals().size, 0
    # publish
    d.publish
    assert_equal m.good_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day)
    assert_equal m.good_deals().size, 0
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.good_deals().size, 0  
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day + 1.days, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.good_deals().size, 0
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day - 1.days)
    assert_equal m.good_deals().size, 1    
    # add a draft 
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, 
      :end_date => Time.zone.today.end_of_day, :expiration_date => Time.zone.today.end_of_day, 
      :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal m.good_deals().size, 1
    # publish
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    d.publish
    assert_equal m.good_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day - 1.days)
    assert_equal m.good_deals().size, 2
    # delete
    assert d.delete
    assert_equal m.good_deals().size, 1  
  end
  
  def test_failed_deals
    m = @emptybob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day - 1.days, 
      :end_date => Time.zone.today.end_of_day - 1.days, :expiration_date => Time.zone.today.end_of_day, 
      :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.failed_deals().size, 0
    # publish
    d.publish
    assert_equal m.failed_deals().size, 0
    # set min to 1
    d.update_attributes(:min => 1)
    assert_equal m.failed_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day)
    assert_equal m.failed_deals().size, 0
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.failed_deals().size, 0  
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day + 1.days, :end_date => Time.zone.today.end_of_day + 1.days)
    assert_equal m.failed_deals().size, 0
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day - 1.days)
    assert_equal m.failed_deals().size, 1    
    # add a draft 
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => Time.zone.today.beginning_of_day, :end_date => Time.zone.today.end_of_day, 
      :expiration_date => Time.zone.today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert_equal m.failed_deals().size, 1
    # publish
    d.publish
    assert_equal m.failed_deals().size, 1
    d.update_attributes(:start_date => Time.zone.today.beginning_of_day - 1.days, :end_date => Time.zone.today.end_of_day - 1.days)
    assert_equal m.failed_deals().size, 1
    # set min to 1
    d.update_attributes(:min => 1)
    assert_equal m.failed_deals().size, 2
    # delete
    assert d.delete
    assert_equal m.failed_deals().size, 1      
  end  
      
end

