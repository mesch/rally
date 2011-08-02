require 'test_helper'

class UserTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :users

  def equal? (u1, u2, columns=[])
    for column in columns
      if u1[column] != u2[column]
        return false
      end
    end
    return true
  end

  def test_auth 
    # check that we can login with a valid email and pass
    assert_equal @test_user, User.authenticate(@test_user.email, "test")
    # valid email, wrong pass - fail
    assert_nil User.authenticate(@test_user.email, "wrongpass")
    # wrong email, valid pass - fail
    assert_nil User.authenticate("non_user@rallycommerce.com", "test")
    #wrong email and pass - fail
    assert_nil User.authenticate("non_user@rallycommerce.com", "wrongpass")
  end

  def test_passwordchange
    # check success
    assert_equal @long_user, User.authenticate(@long_user.email, "longtest")
    #change password
    @long_user.password = @long_user.password_confirmation = "nonbobpasswd"
    assert @long_user.save
    #new password works
    assert_equal @long_user, User.authenticate(@long_user.email, "nonbobpasswd")
    #old pasword doesn't work anymore
    assert_nil   User.authenticate(@long_user.email, "longtest")
    #change back again
    @long_user.password = @long_user.password_confirmation = "longtest"
    assert @long_user.save
    assert_equal @long_user, User.authenticate(@long_user.email, "longtest")
    assert_nil User.authenticate(@long_user.email, "nonbobpasswd")
  end

  def test_disallowed_passwords
    #check thaat we can't create a user with any of the disallowed paswords
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    #too short
    u.password = u.password_confirmation = "wee" 
    assert !u.save     
    assert u.errors['password'].any?
    #too long
    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors['password'].any?
    #empty
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors['password'].any?
    #ok
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    assert u.errors.empty? 
  end

  def test_bad_fields
    #check we cant create a user with an invalid email
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    #no email
    u.email=nil   
    assert !u.save     
    assert u.errors['email'].any?
    #invalid email
    u.email='notavalidemail'   
    assert !u.save     
    assert u.errors['email'].any?
    #ok
    u.email="validtest@abc.com"
    assert u.save  
    assert u.errors.empty?
  end

  def test_collision
    #check can't create new user with existing email
    u = User.new(:email => @existing_user.email)
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save   
    #can create a new user with a new password
    u = User.new(:email => "test@abc.com")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
  end

  def test_case_sensitivity
    u1 = User.new(:email => "test@abc.com")
    u1.password = u1.password_confirmation = "lower"
    assert u1.save
    u2 = Merchant.new(:email => "Test@abc.com")
    u2.password = u2.password_confirmation = "upper"
    assert !u2.save
  end
  
  def test_create
    #check create works and we can authenticate after creation
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert_not_nil u.salt
    assert u.active
    assert_equal u.time_zone, "Pacific Time (US & Canada)"
    assert_nil u.facebook_id
    assert u.save
    assert_equal 10, u.salt.length
    assert_equal u, User.authenticate(u.email, u.password)

    u = User.new(:email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword")
    assert_not_nil u.salt
    assert_not_nil u.password
    assert_not_nil u.hashed_password
    assert u.save
    assert_equal u, User.authenticate(u.email, u.password)
  end

  
  def test_create_complete
    #check that we can create with all fields
    #note - this may get out of sync if new fields are added   
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234", :facebook_id => "12341234",
    :time_zone => "Hawaii", :first_name => "Bobby", :last_name => "Smith", :mobile_number => "4155551212")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert_not_nil u.salt
    assert u.active
    assert u.save
    assert_equal 10, u.salt.length
    assert equal?(u, User.authenticate(u.email, u.password), 
      [:email, :hashed_password, :salt, :activation_code, :activate, :facebook_id, :time_zone, 
        :first_name, :last_name, :mobile_number])
    #check that changing a local field fails match
    u.first_name = "Bob"
    assert !equal?(u, User.authenticate(u.email, u.password), 
      [:email, :hashed_password, :salt, :activation_code, :activate, :facebook_id, :time_zone, 
        :first_name, :last_name, :mobile_number])
  end
  

  def test_send_new_password
    #check user authenticates
    assert_equal  @test_user, User.authenticate(@test_user.email, "test")    
    #send new password
    sent = @test_user.send_new_password
    assert_not_nil sent
    #old password no longer works
    assert_nil User.authenticate(@test_user.email, "test")

### TODO - test this using delayed job?
=begin
    #email sent...
    assert_equal "Your password is ...", sent.subject
    #... to bob
    assert_equal @test_user.email, sent.to[0]
    assert_match Regexp.new("Your email is test_user@rallycommerce.com."), sent.body.raw_source
    #can authenticate with the new password
    new_pass = $1 if Regexp.new("Your new password is (\\w+).") =~ sent.body.raw_source
    assert_not_nil new_pass
    assert_equal  @test_user, User.authenticate(test_user@.email, new_pass)
=end

  end


  def test_rand_str
    new_pass = User.random_string(10)
    assert_not_nil new_pass
    assert_equal 10, new_pass.length
  end

  def test_sha1
    u = User.new
    u.email = "test@abc.com"
    u.activation_code = "1234"
    u.salt = "1000"
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', u.hashed_password
    assert_equal 'b1d27036d59f9499d403f90e0bcf43281adaa844', User.encrypt("bobs_secure_password", "1000")
  end

  def test_protected_attributes
    #check attributes are protected
    u = User.new(:id=>999999, :salt=>"I-want-to-set-my-salt", :email => "test@abc.com", 
      :activation_code => "1234", :password => "newpassword", :password_confirmation => "newpassword")
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt

    u.update_attributes(:id=>999999, :salt=>"I-want-to-set-my-salt", :email => "new@abc.com")
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt
    assert_equal "new@abc.com", u.email
  end
  
  def test_activate
    assert !@inactivated_user.activated
    u = User.find_by_id(@inactivated_user.id)
    assert u.activate
    assert u.activated
    assert equal?(u, @inactivated_user, [:email, :hashed_password, :salt, :activation_code, :active])
  end
  
  def test_inactivate
    assert @test_user.activated
    u = User.find_by_id(@test_user.id)
    assert u.inactivate
    assert !u.activated
    assert equal?(u, @test_user, [:email, :hashed_password, :salt, :activation_code, :active])
  end
  
  def test_update_email
    u = User.find_by_id(@test_user.id)
    # bad format
    assert !u.update_email("bad_format")
    u = User.find_by_id(@test_user.id)
    assert u.activated
    assert equal?(u, @test_user, [:email, :hashed_password, :salt, :active, :activation_code, :activate])
    # success
    assert u.update_email("test@abc.com")
    assert_equal u.email, "test@abc.com"
    assert !u.activated
    assert equal?(u, @test_user, [:hashed_password, :salt, :active])
  end
  
  def test_coupon_count
    Order.delete_all
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    assert_equal u.coupon_count, 0
    # order with no quantity - no change
    o = Order.new(:user_id => u.id, :deal_id => 10)
    assert o.save
    assert_equal u.coupon_count, 0
    # update order with 1 quantity - +1 count
    o.quantity = 1
    o.amount = '10'
    assert o.save
    assert_equal u.coupon_count, 1
    assert_equal u.coupon_count(10), 1
    # update order as authorized - no change
    o.state = Order::AUTHORIZED
    assert o.save
    assert_equal u.coupon_count, 1   
    assert_equal u.coupon_count(10), 1
    # update order as paid - no change
    o.state = Order::PAID
    assert o.save
    assert_equal u.coupon_count, 1   
    assert_equal u.coupon_count(10), 1
    # order with different deal_id with no quantity - no change
    o = Order.new(:user_id => u.id, :deal_id => 11)
    assert o.save
    assert_equal u.coupon_count, 1   
    assert_equal u.coupon_count(10), 1
    # update order with 2 quantity - + 1 general, no change 10, +2 11
    o.quantity = 2
    o.amount = '20'
    assert o.save
    assert_equal u.coupon_count, 3
    assert_equal u.coupon_count(10), 1
    assert_equal u.coupon_count(11), 2
    # order with new user_id with 3 quantity - no change
    o = Order.new(:user_id => u.id+1, :deal_id => 10, :quantity => 3, :amount => '30')
    assert o.save
    assert_equal u.coupon_count, 3
    assert_equal u.coupon_count(10), 1
    assert_equal u.coupon_count(11), 2   
  end    

  def test_unconfirmed_order
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    o = u.unconfirmed_order(10) 
    assert_equal o.quantity, 0
    # create order with different user, different deal - still create a new order
    o = Order.new(:user_id => u.id+1, :deal_id => 11, :quantity => 1, :amount => '20.00')
    assert o.save
    o = u.unconfirmed_order(10) 
    assert_equal o.quantity, 0
    # create order with same user, different deal - still create a new order
    o = Order.new(:user_id => u.id, :deal_id => 11, :quantity => 1, :amount => '20.00')
    assert o.save
    o = u.unconfirmed_order(10)
    assert_equal o.quantity, 0    
    # create order with different user, same deal - still create a new order
    o = Order.new(:user_id => u.id+1, :deal_id => 10, :quantity => 1, :amount => '20.00')
    assert o.save
    o = u.unconfirmed_order(10)
    assert_equal o.quantity, 0
    # create order with same user, same deal, authorized - still create a new order
    o = Order.new(:user_id => u.id, :deal_id => 10, :quantity => 1, :amount => '20.00', :state => Order::AUTHORIZED)
    assert o.save
    o = u.unconfirmed_order(10) 
    assert_equal o.quantity, 0
    # create order with same user, same deal, paid - still create a new order
    o = Order.new(:user_id => u.id, :deal_id => 10, :quantity => 1, :amount => '20.00', :state => Order::PAID)
    assert o.save
    o = u.unconfirmed_order(10) 
    assert_equal o.quantity, 0
    # create order with same user, same deal, unconfirmed - returns that order
    o = Order.new(:user_id => u.id, :deal_id => 10, :quantity => 1, :amount => '20.00')
    assert o.save
    o = u.unconfirmed_order(10) 
    assert_equal o.quantity, 1
  end

end


