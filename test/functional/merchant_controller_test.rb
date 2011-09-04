require 'test_helper'
require 'merchant_controller'

# Re-raise errors caught by the controller.
class MerchantController; def rescue_action(e) raise e end; end

class MerchantControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :merchants

  def setup
    @request.host = "www.rcom.com"
    
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
  
  def test_basic_signup
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'login'
  end

  def test_bad_signup
    #check we can't signup if password_confirmation is different
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "wrong", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]    
    
    #check we can't signup without all required fields
    post :signup, :username => "", :password => "newpassword", :password_confirmation => "newpassword" , 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]

    # password can't be nil to create the merchant object to being with
    post :signup, :username => "newbob", :password => "", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]

    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
    
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "", :name => 'bobs', :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
    
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => "", :time_zone => 'Hawaii', :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
    
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => "", :tos => true
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
    
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => nil
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
  end
  
  def test_signup_subdomain
    # subdomain already exists - fail
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true, :subdomain => "www"
    assert_response :success
    assert flash[:error]
    assert_template "merchant/signup"
    assert_nil session[:merchant_id]
    
    # subdomain empty - ok, but no subdomain added
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true, :subdomain => ""
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'login'
    m = Merchant.find_by_username("newbob")
    assert_nil m.merchant_subdomain
          
    # new subdomain - ok
    post :signup, :username => "newnewbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :tos => true, :subdomain => "newbob"
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'login'
    m = Merchant.find_by_username("newnewbob")
    assert_equal m.merchant_subdomain.subdomain, "newbob"
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
    get :account
    assert_response :redirect
    assert_redirected_to :action=>'login'
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'login'
    get :accept_terms
    assert_response :redirect
    assert_redirected_to :action=>'login'      
    #login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #can access now
    get :account
    assert_response :success
    assert_nil flash[:error]
    assert_template "merchant/account"
    get :home
    assert_response :success
    assert_nil flash[:error]
    assert_template "merchant/home"
    get :accept_terms
    assert_response :success
    assert_nil flash[:error]
    assert_template "merchant/accept_terms"    
  end
  
  def test_terms
    @existingbob.update_attributes(:terms => false)
    # go to home - redirected to login
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'login'
    # got to accept_terms - redirected to login    
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'login'
    # login - redirected to home
    post :login, :username => "existingbob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    # go to home - redirected to accept_terms
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'accept_terms'
    # accept_terms without terms - stay on page  
    post :accept_terms
    assert_response :success
    assert flash[:error]
    assert_template "merchant/accept_terms"
    assert !Merchant.find_by_id(@existingbob.id).terms
    # accept_terms with terms - redirected to home
    post :accept_terms, :terms => 1
    assert_response :redirect
    assert_redirected_to :action=>'home'
    assert Merchant.find_by_id(@existingbob.id).terms
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
  
  def test_missing_merchant_id_activation
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
    assert_redirected_to :action => 'home'
    assert session[:merchant_id]
    #name too long
    put :account, :merchant => {:name => '123456789012345678901234567890123456789012345678900', :time_zone => @bob.time_zone}
    assert_response :success
    assert flash[:error]
    assert_template "merchant/account"
    assert_equal Merchant.find(@bob.id).name, old_name
    #success
    put :account, :merchant => {:name => '1234567890', :time_zone => @bob.time_zone}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    assert_template "merchant/account"
    assert_equal Merchant.find(@bob.id).name, '1234567890' 
  end

  def test_change_subdomain
    #assuming existingbob doesn't have subdomain set
    #can login
    post :login, :username => @existingbob.username, :password => "test"
    assert_response :redirect
    assert_redirected_to :action => 'home'
    assert session[:merchant_id]
    # no subdomain set
    m = Merchant.find_by_id(session[:merchant_id])
    assert_nil m.merchant_subdomain
    # empty subdomain - do nothing
    put :account, :merchant => {:name => @existingbob.name, :time_zone => @existingbob.time_zone, :subdomain => ""}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    m = Merchant.find_by_id(session[:merchant_id])
    assert_nil m.merchant_subdomain
    # taken subdomain - fail
    put :account, :merchant => {:name => @existingbob.name, :time_zone => @existingbob.time_zone, :subdomain => "www"}
    assert_response :success
    assert flash[:error]
    m = Merchant.find_by_id(session[:merchant_id])
    assert_nil m.merchant_subdomain
    # new subdomain - save
    put :account, :merchant => {:name => @existingbob.name, :time_zone => @existingbob.time_zone, :subdomain => "existingbob"}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    m = Merchant.find_by_id(session[:merchant_id])
    assert m.merchant_subdomain.subdomain, "existingbob"
    # same subdomain - do nothing
    put :account, :merchant => {:name => @existingbob.name, :time_zone => @existingbob.time_zone, :subdomain => "existingbob"}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    m = Merchant.find_by_id(session[:merchant_id])
    assert m.merchant_subdomain.subdomain, "existingbob"
    # empty subdomain - do nothing (for now?)
    put :account, :merchant => {:name => @existingbob.name, :time_zone => @existingbob.time_zone, :subdomain => ""}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    m = Merchant.find_by_id(session[:merchant_id])
    assert m.merchant_subdomain.subdomain, "existingbob"
  end

  # cannot change time zone after creation ...
  def test_change_time_zone
    #can login
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    assert session[:merchant_id]
    #success
    put :account, :merchant => {:name => @bob.name, :time_zone => 'Hawaii'}
    assert_response :redirect
    assert_redirected_to :action => 'account'
    assert flash[:notice]
    assert_not_equal Merchant.find(@bob.id).time_zone, 'Hawaii'
    # go back to page and check time zone
    get :account
    assert_response :success
    assert_not_equal Time.zone.name, 'Hawaii'
  end

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
    #logout and login again
    get :logout
    assert_nil session[:merchant_id]
    post :login, :username => "bob", :password => "test"
    assert_response :redirect
    #this time we were redirected to home
    assert_redirected_to :action=>'home'
  end

  # Deal methods
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
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
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
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 0    
    post :create_deal, :title => 'dealio', :start_date => nil, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => nil, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => nil, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => nil, :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => nil,
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => nil, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => nil, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => nil
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
  end
  
  def test_create_non_numbers
    self.login
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 'a', :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 'a', :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 'a'
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"
  end  
  
  def test_create_deal_field_lengths
    self.login
    # title - 100 chars
    string = ""
    length = 101
    length.times{ string << "a"}
    post :create_deal, :title => string, :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:error]
    assert_response :success
    assert_template "merchant/_deal_form"   
  end
  
  def test_create_deal_full
    self.login
    #create full
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :description => 'blahblahblah', :terms => 'you have to ...', :min => 20, :max => '100', :limit => '5'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
  end

  def test_update_deal
    self.login
    #create full
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :description => 'blahblahblah', :terms => 'you have to ...', :min => 20, :max => '100', :limit => '5'
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
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'drafts'
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'new name'      
  end
  
  def test_update_deal_full
    self.login
    #create basic
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
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
      :deal_price => '15.00', :deal_value => '30.00',  :min => '5', :max => '100', :limit => '3',
      :description => 'blahblahblah', :terms => 'you have to ...'
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'drafts'
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'new name'
  end

  def test_update_deal_field_lengths
    self.login
    #create basic
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
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
    assert_response :success
    assert_template "merchant/_deal_form"
    # verify in DB
    deal = Deal.find(deal.id)
    assert_equal deal.title, 'dealio' 
  end
  
  def test_publish_deal
    self.login
    # create
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert !deal.published
    assert_equal deal.max, 0
    # publish
    get :publish_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'current'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert deal.published
    assert_equal deal.max, 0    
  end
  
  def test_delete_deal
    self.login
    # create
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.active, true
    # delete
    get :delete_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'drafts'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.active, false
  end
  
  def test_tip_deal
    self.login
    # create
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.min, 1
    assert_equal deal.confirmed_coupon_count, 0
    # delete
    get :tip_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'success'
    # verify in DB
    deals = Deal.find(:all, :conditions => {:merchant_id => @bob.id, :title => 'dealio'})
    assert_equal deals.size, 1
    deal = deals[0]
    assert_equal deal.min, 0    
  end
    
  def test_access_other_deals
    Deal.delete_all
    # can access my deal (edit/update/publish)
    self.login
    post :create_deal, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    deal = @bob.deals[0]
    get :edit_deal, :id => deal.id
    assert_response :success
    assert_template "merchant/_deal_form"
    post :update_deal, :id => deal.id, :title => 'new dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'drafts'
    get :publish_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'current'
    get :delete_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'drafts'
    get :tip_deal, :id => deal.id
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'deals', :selector=>'success'    
    # others can't access my deal
    post :login, :username => "emptybob", :password => "test"
    get :edit_deal, :id => deal.id
    assert_nil flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'home'
    post :update_deal, :id => deal.id, :title => 'new dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00',
      :min => 1, :max => 0, :limit => 0
    assert_nil flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'home'
    get :publish_deal, :id => deal.id
    assert_nil flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'home'
    get :delete_deal, :id => deal.id
    assert_nil flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'home'
    get :tip_deal, :id => deal.id
    assert_nil flash[:notice]
    assert_response :redirect
    assert_redirected_to :action=>'home'    
  end

  def test_subdomain_general
    old_host = @request.host
    # go to login - no redirection
    get :login
    assert_response :success
    assert_template "merchant/login"
    assert_equal @request.host, old_host
    # empty subdomain - redirected
    @request.host = @request.host.gsub(/^www\./, '')
    assert_not_equal @request.host, old_host
    get :login
    assert_response :redirect
    assert_redirected_to :action => :login, :host => old_host    
    # use invalid subdomain - redirected
    @request.host = @request.host.gsub(/^www\./, 'invalid.')
    assert_not_equal @request.host, old_host
    get :login
    assert_response :redirect
    assert_redirected_to :action => :login, :host => old_host
  end

  def test_home
    # dates are not set in session
    start_date = session[:start_date]
    end_date = session[:end_date]
    assert_nil start_date
    assert_nil end_date
    self.login
    # direct navigation
    get :home
    assert_response :success
    assert_template "merchant/home"
    start_date = session[:start_date]
    end_date = session[:end_date]
    assert_nil start_date
    assert_nil end_date
    # invalid date format
    post :home, :start_date => '1234', :end_date => '1234'
    assert_response :redirect
    assert_redirected_to :action => :home
    assert flash[:error]
    assert_equal start_date, session[:start_date]    
    assert_equal end_date, session[:end_date]
    # start_date > end_date - invalid
    post :home, :start_date => '01/02/2012', :end_date => '01/01/2012'
    assert_response :redirect
    assert_redirected_to :action => :home
    assert flash[:error]
    assert_equal start_date, session[:start_date]    
    assert_equal end_date, session[:end_date]
    assert_equal end_date, session[:end_date]
    # end_date - start_date > 1 year - invalid
    post :home, :start_date => '01/01/2011', :end_date => '01/02/2012'
    assert_response :redirect
    assert_redirected_to :action => :home
    assert flash[:error]
    assert_equal start_date, session[:start_date]    
    assert_equal end_date, session[:end_date]      
    # valid date range
    post :home, :start_date => '01/01/2011', :end_date => '01/01/2011'
    assert_response :success
    assert_template "merchant/home"
    assert flash[:error]
    assert_not_equal start_date, session[:start_date]    
    assert_not_equal end_date, session[:end_date]    
  end

end