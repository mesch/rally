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
    # check that we can login with a valid username and pass
    assert_equal  @test_user, User.authenticate(@test_user.username, "test")
    # valid email and pass
    assert_equal  @test_user, User.authenticate(@test_user.email, "test")
    # valid username, wrong pass - fail
    assert_nil    User.authenticate(@test_user, "wrongpass")
    # valid email, wrong pass - fail
    assert_nil    User.authenticate(@test_user, "wrongpass")
    # wrong username or email, valid pass - fail
    assert_nil    User.authenticate("nonbob", "test")
    #wrong username and pass - fail
    assert_nil    User.authenticate("nonbob", "wrongpass")
  end

  def test_passwordchange
    # check success
    assert_equal @long_user, User.authenticate("long_user", "longtest")
    #change password
    @long_user.password = @long_user.password_confirmation = "nonbobpasswd"
    assert @long_user.save
    #new password works
    assert_equal @long_user, User.authenticate("long_user", "nonbobpasswd")
    #old pasword doesn't work anymore
    assert_nil   User.authenticate("long_user", "longtest")
    #change back again
    @long_user.password = @long_user.password_confirmation = "longtest"
    assert @long_user.save
    assert_equal @long_user, User.authenticate("long_user", "longtest")
    assert_nil   User.authenticate("long_user", "nonbobpasswd")
  end

  def test_disallowed_passwords
    #check thaat we can't create a merchant with any of the disallowed paswords
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
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
    #check we cant create a merchant with an invalid username
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    #too short
    u.username = "x"
    assert !u.save     
    assert u.errors['username'].any?
    #too long
    u.username = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebob"
    assert !u.save     
    assert u.errors['username'].any?
    #empty
    u.username = ""
    assert !u.save
    assert u.errors['username'].any?
    #ok
    u.username = "okbob"
    assert u.save
    assert u.errors.empty?
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
    #check can't create new user with existing username
    u = User.new(:username => @existing_user.username, :email => "test@abc.com")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save
    #check can't create new user with existing email
    u = User.new(:username => "nonexistingbob", :email => @existing_user.email)
    u.password = u.password_confirmation = "bobs_secure_password"
    assert !u.save    
    #can create a new user with a new username and password
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
  end


  def test_create
    #check create works and we can authenticate after creation
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert_not_nil u.salt
    assert u.active
    assert_equal u.time_zone, "Pacific Time (US & Canada)"
    assert u.save
    assert_equal 10, u.salt.length
    assert_equal u, User.authenticate(u.username, u.password)

    u = User.new(:username => "newbob", :email => "testtest@abc.com", :activation_code => "1234",
      :password => "newpassword", :password_confirmation => "newpassword")
    assert_not_nil u.salt
    assert_not_nil u.password
    assert_not_nil u.hashed_password
    assert u.save
    assert_equal u, User.authenticate(u.username, u.password)
  end

  
  def test_create_complete
    #check that we can create with all fields
    #note - this may get out of sync if new fields are added   
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234",
    :time_zone => "Hawaii", :first_name => "Bobby", :last_name => "Smith", :mobile_number => "4155551212")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert_not_nil u.salt
    assert u.active
    assert u.save
    assert_equal 10, u.salt.length
    assert equal?(u, User.authenticate(u.username, u.password), 
      [:username, :email, :hashed_password, :salt, :activation_code, :activate, :time_zone, 
        :first_name, :last_name, :mobile_number])
    #check that changing a local field fails match
    u.first_name = "Bob"
    assert !equal?(u, User.authenticate(u.username, u.password), 
      [:username, :email, :hashed_password, :salt, :activation_code, :activate, :time_zone, 
        :first_name, :last_name, :mobile_number])
  end
  

  def test_send_new_password
    #check user authenticates
    assert_equal  @test_user, User.authenticate("test_user", "test")    
    #send new password
    sent = @test_user.send_new_password
    assert_not_nil sent
    #old password no longer works
    assert_nil User.authenticate("test_user", "test")

### TODO - test this using delayed job?
=begin
    #email sent...
    assert_equal "Your password is ...", sent.subject
    #... to bob
    assert_equal @test_user.email, sent.to[0]
    assert_match Regexp.new("Your username is bob."), sent.body.raw_source
    #can authenticate with the new password
    new_pass = $1 if Regexp.new("Your new password is (\\w+).") =~ sent.body.raw_source
    assert_not_nil new_pass
    assert_equal  @test_user, User.authenticate("test_user", new_pass)
=end

  end


  def test_rand_str
    new_pass = User.random_string(10)
    assert_not_nil new_pass
    assert_equal 10, new_pass.length
  end

  def test_sha1
    u = User.new
    u.username = "nonexistingbob"
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
    u = User.new(:id=>999999, :salt=>"I-want-to-set-my-salt", :username => "badbob", :email => "test@abc.com", 
      :activation_code => "1234", :password => "newpassword", :password_confirmation => "newpassword")
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt

    u.update_attributes(:id=>999999, :salt=>"I-want-to-set-my-salt", :username => "verybadbob")
    assert u.save
    assert_not_equal 999999, u.id
    assert_not_equal "I-want-to-set-my-salt", u.salt
    assert_equal "verybadbob", u.username
  end
  
  def test_activate
    assert !@inactivated_user.activated
    u = User.find(@inactivated_user.id)
    assert u.activate
    assert u.activated
    assert equal?(u, @inactivated_user, [:username, :hashed_password, :email, :salt, :activation_code, :active])
  end
  
  def test_inactivate
    assert @test_user.activated
    u = User.find(@test_user)
    assert u.inactivate
    assert !u.activated
    assert equal?(u, @test_user, [:username, :hashed_password, :salt, :email, :activation_code, :active])
  end
  
  def test_update_email
    u = User.find(@test_user)
    # bad format
    assert !u.update_email("bad_format")
    u = User.find(@test_user)
    assert u.activated
    assert equal?(u, @test_user, [:username, :email, :hashed_password, :salt, :active, :activation_code, :activate])
    # success
    assert u.update_email("test@abc.com")
    assert_equal u.email, "test@abc.com"
    assert !u.activated
    assert equal?(u, @test_user, [:username, :hashed_password, :salt, :active])
  end
  
  def test_coupon_count
    u = User.new(:username => "nonexistingbob", :email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    assert_equal u.coupon_count, 0
    c = Coupon.new(:user_id => u.id, :deal_id => 1, :order_id => 3, :deal_code_id => 100)
    assert c.save
    assert_equal u.coupon_count, 1
    assert_equal u.coupon_count(1), 1
    c = Coupon.new(:user_id => u.id, :deal_id => 1, :order_id => 4, :deal_code_id => 100)
    assert c.save
    assert_equal u.coupon_count, 2
    assert_equal u.coupon_count(1), 2
    c = Coupon.new(:user_id => u.id, :deal_id => 1, :order_id => 4, :deal_code_id => 100)
    assert c.save
    assert_equal u.coupon_count, 3
    assert_equal u.coupon_count(1), 3          
    c = Coupon.new(:user_id => u.id, :deal_id => 2, :order_id => 5, :deal_code_id => 100)
    assert c.save
    assert_equal u.coupon_count, 4
    assert_equal u.coupon_count(1), 3
    assert_equal u.coupon_count(2), 1
  end    
      
end


