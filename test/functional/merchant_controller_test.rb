require 'test_helper'
require 'merchant_controller'

# Re-raise errors caught by the controller.
class MerchantController; def rescue_action(e) raise e end; end

class MerchantControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :merchants

  def setup
    @controller = MerchantController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "localhost"
    
    @start = Time.zone.today
    @end = Time.zone.today + 1.days
    @expiration = Time.zone.today + 1.months
  end

  def login
    post :login, :username => "bob", :password => "test"
  end
    
  def test_auth_bob
    #check we can login
    post :login, :username => "bob", :password => "test"
    assert session[:merchant_id]
    assert_equal @bob, Merchant.find(session[:merchant_id])
    assert_response :redirect
    assert_redirected_to :action=>'home'
  end

  def test_set_time_zone
    old_time_zone = Time.zone.name
    # Time zone should be different than local time
    post :login, :username => "existingbob", :password => "test"
    get :home
    assert_equal Time.zone.name, @existingbob.time_zone
    assert_not_equal Time.zone.name, old_time_zone
  end
  
  def test_signup
    #unfortunately can't test passing captcha - this will fail for now
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@mcbob.com" 
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_template "merchant/signup"
  end

  def test_bad_signup
    #check we can't signup without all required fields
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "wrong" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]

    post :signup, :username => "yo", :password => "newpassword", :password_confirmation => "newpassword" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]

    post :signup, :username => "yo", :password => "newpassword", :password_confirmation => "wrong" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
  end

  def test_invalid_login
    #can't login with incorrect password
    post :login, :username => "bob", :password => "not_correct"
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_template "merchant/login"
  end
  
  def test_inactive_login
    #can't login if merchant is not active
    post :login, :username => "inactive", :password => "test"
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_template "merchant/login"
  end
  
  def test_inactivated_login
    #redirected to activate account
    post :login, :username => "inactivated", :password => "test"
    assert_response :redirect
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_redirected_to :action=>'reactivate'
  end

  def test_login_logoff
    #login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #then logoff
    get :logout
    assert_response :redirect
    assert_nil session[:merchant_id]
    assert_redirected_to :action=>'login'
  end

  def test_forgot_password
    #we can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #logout
    get :logout
    assert_response :redirect
    assert_nil session[:merchant_id]
    #enter an email that doesn't exist
    post :forgot_password, :username => @bob.username, :email=>"notauser@doesntexist.com"
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_template "merchant/forgot_password"
    #enter a username that doesn't exist
    post :forgot_password, :username => "testtesttest", :email=>"notauser@doesntexist.com"
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    assert_template "merchant/forgot_password"
    #enter bobs email
    post :forgot_password, :username => @bob.username, :email=>@bob.email   
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_login_required
    #can't access account page if not logged in
    get :account
    assert_response :redirect
    assert_redirected_to :action=>'login'
    #login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #can access it now
    get :account
    assert_response :success
    assert_nil flash[:error]
    assert_template "merchant/account"
  end

  def test_change_password
    #can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #try to change password
    #passwords dont match
    post :change_password, :password => "newpass", :password_confirmation => "newpassdoesntmatch"
    assert_response :redirect
    assert flash[:error]
    #empty password
    post :change_password, :password => "", :password_confirmation => ""
    assert_response :redirect
    assert flash[:error]
    #success - password changed
    post :change_password, :password => "newpass", :password_confirmation => "newpass"
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'account'
    #logout
    get :logout
    assert_response :redirect
    assert_nil session[:merchant_id]
    #old password no longer works
    post :login, :username => @bob.username, :password => "test"
    assert_response :success
    assert_nil session[:merchant_id]
    assert flash[:error]
    #new password works
    post :login, :username => @bob.username, :password => "newpass"
    assert_response :redirect
    assert session[:merchant_id]
  end

  def test_reactivate_email
    #email sent from reactivate page
    #enter an email that doesn't exist
    post :reactivate, :username => @bob.username, :email=>"notauser@doesntexist.com"
    assert_response :success
    assert_nil session[:merchant_id]
    assert_template "merchant/reactivate"
    assert flash[:error]
    #enter a user that doesn't exist
    post :reactivate, :username => "testertesterson", :email=>@bob.email
    assert_response :success
    assert_nil session[:merchant_id]
    assert_template "merchant/reactivate"
    assert flash[:error]
    #enter a user and email that don't match
    post :reactivate, :username => @bob.username, :email=>"test@abc.com"
    assert_response :success
    assert_nil session[:merchant_id]
    assert_template "merchant/reactivate"
    assert flash[:error]
    #enter an activated username and email
    post :reactivate, :username => @bob.username, :email=>@bob.email
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login' 
    #enter inactivated username and email
    post :reactivate, :username => @inactivated.username, :email=>@inactivated.email  
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end
  
  def test_activation
    get :activate, :activation_code => '1234567890', :merchant_id => @inactivated.id
    assert_response :redirect
    assert_nil session[:merchant_id]
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_missing_code_activation
    get :activate, :merchant_id => @inactivated.id
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action => "reactivate"  
  end
  
  def test_missing_code_activation
    get :activate, :activation_code => '1234567890'
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action => "reactivate"   
  end

  def test_invalid_merchant_id_activation
    get :activate, :activation_code => '1234567890', :merchant_id => 0
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action=>'login'    
  end
  
  def test_invalid_code_activation
    get :activate, :activation_code => '1111111111', :merchant_id => @inactivated.id
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action=>'login'    
  end
  
  def test_change_email
    old_email = @bob.email
    #can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #wrong email format
    post :change_email, :email => "badformat"
    assert_response :success
    assert flash[:error]
    assert_template "merchant/change_email"
    assert_equal Merchant.find(@bob.id).email, old_email    
    #success - email changed
    post :change_email, :email => "test@abc.com"
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'logout'
    assert_equal Merchant.find(@bob.id).email, "test@abc.com"
    #can't find old_email
    post :forgot_password, :username => @bob.username, :email=>old_email
    assert_response :success
    assert flash[:error]
    assert_template "merchant/forgot_password"
    #can find new email
    post :forgot_password, :username => @bob.username, :email=>"test@abc.com"   
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end
  
  def test_change_name
    old_name = @bob.name
    #can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #name too long
    post :account, :name => '123456789012345678901234567890123456789012345678900', :time_zone => @bob.time_zone
    assert_response :success
    assert flash[:error]
    assert_template "merchant/account"
    assert_equal Merchant.find(@bob.id).name, old_name
    #success
    post :account, :name => '1234567890', :time_zone => @bob.time_zone
    assert_response :success
    assert flash[:notice]
    assert_template "merchant/account"
    assert_equal Merchant.find(@bob.id).name, '1234567890' 
  end

  # cannot change time zone after creation ...
  def test_change_time_zone
    #can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #success
    post :account, :name => @bob.name, :time_zone => 'Hawaii'
    assert_response :success
    assert flash[:notice]
    assert_template "merchant/account"
    assert_not_equal Merchant.find(@bob.id).time_zone, 'Hawaii'
    # go back to page and check time zone
    get :account
    assert_response :success
    assert_not_equal Time.zone.name, 'Hawaii'
  end

## unable to test due to @request not getting set in ApplicationController
=begin
  def test_return_to
    #cant access account without being logged in
    get :account
    assert_response :redirect
    assert_redirected_to :action=>'login'
    assert session[:merchant_return_to]
    #login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    #redirected to account
    assert_redirected_to :action=>'account'
    assert_nil session[:merchant_return_to]
    assert session[:merchant_id]
    assert flash[:notice]
    #logout and login again
    get :logout
    assert_nil session[:merchant_id]
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    #this time we were redirected to home
    assert_redirected_to :action=>'home'
  end
=end

  def test_get_to_deals
    self.login
    get :deals
    assert_response :success
    assert_template "merchant/deals"    
  end

  def test_create_deal
    self.login
    #create basic
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
  end
  
  def test_create_deal_missing_fields
    self.login
    post :create_deal, :title => nil, :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal' 
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 0    
    post :create_deal, :title => 'dealio', :start_date => nil, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => nil, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => nil, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => nil, :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => nil
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'
  end
  
  def test_create_deal_field_lengths
    self.login
    # title - 50 chars
    string = ""
    length = 51
    length.times{ string << "a"}
    post :create_deal, :title => string, :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'new_deal'    
  end
  
  def test_create_deal_full
    self.login
    #create full
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :description => 'blahblahblah', :terms => 'you have to ...', :max => '100', :limit => '5',
      :video => 'http://www.mediacollege.com/video-gallery/testclips/barsandtone.flv'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
  end

# Behavioral Testing? In order to upload files?  
=begin
  def test_create_deal_images
    
  end

  def test_create_deal_codes
    
  end
=end

  def test_update_deal
    self.login
    #create full
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :description => 'blahblahblah', :terms => 'you have to ...', :max => '100', :limit => '5',
      :video => 'http://www.mediacollege.com/video-gallery/testclips/barsandtone.flv'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.title, 'dealio'
    #edit title
    post :update_deal, :id => deal.id, :title => 'new name', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'new name'      
  end
  
  def test_update_deal_full
    self.login
    #create basic
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.title, 'dealio'
    #edit all fields
    post :update_deal, :id => deal.id, :title => 'new name', :start_date => @start + 1.days, 
      :end_date => @end + 1.days, :expiration_date => @expiration + 1.days,
      :deal_price => '15.00', :deal_value => '30.00',  :max => '10', :limit => '3',
      :description => 'blahblahblah', :terms => 'you have to ...', :max => '100', :limit => '5',
      :video => 'http://www.mediacollege.com/video-gallery/testclips/barsandtone.flv'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'new name'
  end

  def test_update_deal_field_lengths
    self.login
    #create basic
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.title, 'dealio'
    # edit title
    # title - 50 chars
    string = ""
    length = 51
    length.times{ string << "a"}
    post :update_deal, :id => deal.id, :title => string
    assert flash[:error]
    assert_response :redirect
    assert_redirected_to :action => 'edit_deal'
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'dealio' 
  end

end