require 'test_helper'
require 'user_controller'

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures = true

  fixtures :users

  def setup
    @request.host = "www.rcom.com"
    @start = Time.zone.today.beginning_of_day
    @end = Time.zone.today.end_of_day
    @expiration = Time.zone.today.end_of_day
  end

  def login
    post :login, :email => @test_user.email, :password => "test"
  end

  def test_auth
    #check we can login
    # valid email
    post :login, :email => @test_user.email, :password => "test"
    assert session[:user_id]
    assert_equal @test_user, User.find(session[:user_id])
    assert_response :redirect
    assert_redirected_to :action=>'home'  
  end

  def test_set_time_zone
    old_time_zone = Time.zone.name
    # Time zone should be different than local time (as set in users.yml)
    post :login, :email => @existing_user.email, :password => "test"
    get :home
    assert_equal Time.zone.name, @existing_user.time_zone
    assert_not_equal Time.zone.name, old_time_zone
  end

  def test_signup
    post :signup, :email => "newbob@mcbob.com", :password => "newpassword", :password_confirmation => "newpassword", :terms => "1"
    assert_response :redirect
    assert_redirected_to :action => 'login'
    assert flash[:notice]
    assert_nil session[:user_id]
  end

  def test_bad_signup
    # Note - can't test captcha
    # Missing terms
    post :signup, :email => "newbob@mcbob.com", :password => "newpassword", :password_confirmation => "newpassword", :terms => nil
    assert_response :success
    assert_template "user/signup"
    assert flash[:error] 
    # Empty email
    post :signup, :email => "", :password => "newpassword", :password_confirmation => "newpassword", :terms => "1"
    assert_response :success
    assert flash[:error]
    assert_template "user/signup"    
    # Invalid email
    post :signup, :email => "1234", :password => "newpassword", :password_confirmation => "newpassword", :terms => "1"
    assert_response :success
    assert_template "user/signup"
    assert flash[:error]
    # Existing email
    post :signup, :email => @test_user.email, :password => "newpassword", :password_confirmation => "newpassword", :terms => "1"
    assert_response :success
    assert flash[:error]
    assert_template "user/signup"
    # Empty password
    post :signup, :email => "newbob@mcbob.com", :password => "", :password_confirmation => "", :terms => "1"
    assert_response :success
    assert_template "user/signup"
    assert flash[:error]    
    # Invalid password
    post :signup, :email => "newbob@mcbob.com", :password => "a", :password_confirmation => "a", :terms => "1"
    assert_response :success
    assert_template "user/signup"
    assert flash[:error]
    # Empty password confirmation
    post :signup, :email => "newbob@mcbob.com", :password => "newpassword", :password_confirmation => "", :terms => "1"
    assert_response :success
    assert_template "user/signup"
    assert flash[:error]
    # Password confirmation doesn't match
    post :signup, :email => "newbob@mcbob.com", :password => "newpassword", :password_confirmation => "wrong", :terms => "1"
    assert_response :success
    assert_template "user/signup"
    assert flash[:error]
  end

  def test_invalid_login
    #can't login with incorrect password
    post :login, :email => @test_user.email, :password => "not_correct"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/login"
  end

  def test_inactive_login
    #can't login if user is not active
    post :login, :email => @inactive_user.email, :password => "test"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/login"
  end

  def test_inactivated_login
    #redirected to activate account
    post :login, :email => @inactivated_user.email, :password => "test"
    assert_response :redirect
    assert_nil session[:user_id]
    assert flash[:error]
    assert_redirected_to :action=>'reactivate'
  end

  def test_login_logoff
    #login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #then logoff
    get :logout
    assert_response :redirect
    assert_nil session[:user_id]
    assert_redirected_to :action=>'login'
  end

  def test_forgot_password
    #we can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #logout
    get :logout
    assert_response :redirect
    assert_nil session[:user_id]
    #enter an email that doesn't exist
    post :forgot_password, :email => "notauser@doesntexist.com"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/forgot_password"
    #enter valid email
    post :forgot_password, :email => @test_user.email 
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
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #can access it now
    get :account
    assert_response :success
    assert_nil flash[:error]
    assert_template "user/account"
  end

  def test_change_password
    #can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
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
    assert_nil session[:user_id]
    #old password no longer works
    post :login, :email => @test_user.email, :password => "test"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    #new password works
    post :login, :email => @test_user.email, :password => "newpass"
    assert_response :redirect
    assert session[:user_id]
  end

  def test_reactivate_email
    #email sent from reactivate page
    #enter an email that doesn't exist
    post :reactivate, :email => "test@abc.com"
    assert_response :success
    assert_nil session[:user_id]
    assert_template "user/reactivate"
    assert flash[:error]
    #enter an activated email
    post :reactivate, :email => @test_user.email
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
    #enter an inactivated email
    post :reactivate, :email => @inactivated_user.email
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_activation
    get :activate, :activation_code => @inactivated_user.activation_code, :user_id => @inactivated_user.id
    assert_response :redirect
    assert_nil session[:user_id]
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_missing_user_id_activation
    get :activate, :activation_code => @inactivated_user.activation_code
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action => "reactivate"   
  end

  def test_missing_code_activation
    get :activate, :user_id => @inactivated_user.id
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action => "reactivate"  
  end

  def test_invalid_user_id_activation
    get :activate, :activation_code => @inactivated_user.activation_code, :user_id => 0
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action=>'login'    
  end

  def test_invalid_code_activation
    get :activate, :activation_code => '1111111111', :user_id => @inactivated_user.id
    assert_response :redirect
    assert flash[:error]
    assert_redirected_to :action=>'login'    
  end

  def test_change_email
    old_email = @test_user.email
    #can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #wrong email format
    post :change_email, :email => "badformat"
    assert_response :success
    assert flash[:error]
    assert_template "user/change_email"
    assert_equal User.find(@test_user.id).email, old_email    
    #success - email changed
    post :change_email, :email => "test@abc.com"
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'logout'
    assert_equal User.find(@test_user.id).email, "test@abc.com"
    #can't find old_email
    post :forgot_password, :email => old_email
    assert_response :success
    assert flash[:error]
    assert_template "user/forgot_password"
    #can find new email
    post :forgot_password, :email=>"test@abc.com"   
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_change_account_basic
    #just changing name
    #can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #name too long
    post :account, :first_name => '123456789012345678901234567890123456789012345678900'
    assert_response :success
    assert flash[:error]
    assert_template "user/account"
    assert_equal User.find(@test_user.id).first_name, @test_user.first_name
    #success
    post :account, :first_name => 'tester'
    assert_response :success
    assert flash[:notice]
    assert_template "user/account"
    assert_not_equal User.find(@test_user.id).first_name, @test_user.first_name
    assert_equal User.find(@test_user.id).first_name, 'tester' 
  end
  
  def test_change_account_full
    #can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #success
    post :account, :first_name => 'tester', :last_name => 'testerson'
    assert_response :success
    assert flash[:notice]
    assert_template "user/account"
    assert_equal User.find(@test_user.id).first_name, 'tester'
    assert_equal User.find(@test_user.id).last_name, 'testerson'
  end

  # cannot change time zone for user (yet)
  def test_change_time_zone
    #can login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #success
    post :account, :first_name => @test_user.first_name, :time_zone => 'Hawaii'
    assert_response :success
    assert flash[:notice]
    assert_template "user/account"
    assert_not_equal User.find(@test_user.id).time_zone, 'Hawaii'
    # go back to page and check time zone
    get :account
    assert_response :success
    assert_not_equal Time.zone.name, 'Hawaii'
  end

  def test_deals_page_basic
    # can access the deals page without logging in (but session isn't set)
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert_nil session[:user_id]
    # session will be set if we login first
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert session[:user_id]
  end

  def test_deals_page_multiple_deals
    Deal.delete_all
    m = @bob
    # no deals - stay on deals
    get :deals
    assert_response :success
    assert_template "user/deals"        
    # one deal - go directly to deal
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    get :deals
    assert_response :redirect
    assert_redirected_to :action=>'deal', :id => d.id
    # two deals - stay on deals
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    get :deals
    assert_response :success
    assert_template "user/deals"        
  end
  
  def test_deals_page_subdomain
    Deal.delete_all
    m = @existingbob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)    
    assert d.publish
    m = @bob
    d = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    # no subdomain - multiple deals - stay on deals
    get :deals
    assert_response :success
    assert_template "user/deals"    
    # subdomain "bob" - one deal - go to deal
    @request.host = @request.host.gsub(/^www\./, "#{@bob.merchant_subdomain.subdomain}.")
    get :deals
    assert_response :redirect
    assert_redirected_to :action=>'deal', :id => d.id
  end
  
  def test_deal_page_no_deal
    get :deal, :id => 0
    assert_response :redirect
    assert_redirected_to :action=>'home'
  end

  def test_deals_page_timezone
    Deal.delete_all
    # merchant's time zone
    Time.zone = 'US/Pacific'
    # started deal
    d = Deal.new(:merchant_id => @emptybob.id, :title => 'dealio', :start_date => Time.zone.now - 10.minutes, :end_date => Time.zone.now + 10.minutes, 
      :expiration_date => Time.zone.now + 10.minutes, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    # User w/ same time zone - go directly to deal page
    @test_user.update_attributes!(:time_zone => 'US/Pacific')
    get :deals
    assert_response :redirect
    assert_redirected_to :action=>'deal', :id => d.id
    # User w/ earlier time zone - shouldn't change
    @test_user.update_attributes!(:time_zone => 'US/Eastern')
    get :deals
    assert_response :redirect
    assert_redirected_to :action=>'deal', :id => d.id   
    # User w/ later time zone - shouldn't change
    @test_user.update_attributes!(:time_zone => 'US/Hawii')
    get :deals
    assert_response :redirect
    assert_redirected_to :action=>'deal', :id => d.id
    # ended deal
    d.update_attributes!(:end_date => Time.zone.now - 10.minutes)
    # User w/ same time zone - stays on deal page
    @test_user.update_attributes!(:time_zone => 'US/Pacific')    
    get :deals
    assert_response :success
    assert_template "user/deals"
    # User w/ earlier time zone - shouldn't change
    @test_user.update_attributes!(:time_zone => 'US/Eastern')
    get :deals
    assert_response :success
    assert_template "user/deals"  
    # User w/ later time zone - shouldn't change
    @test_user.update_attributes!(:time_zone => 'US/Hawii')
    get :deals
    assert_response :success
    assert_template "user/deals"   
    # reset Time.zone
    Time.zone = 'Etc/UTC'
  end
  
  def test_coupon_page
    self.login
    m = @existingbob
    # Create Deal
    deal = Deal.new(:merchant_id => m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert deal.save
    dc = DealCode.new(:deal_id => deal.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => deal.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    deal = Deal.find_by_id(deal.id)
    assert deal.publish
    # Create Order
    order = Order.new(:user_id => @test_user.id, :deal_id => deal.id, :state => Order::AUTHORIZED)
    assert order.save
    # Create Coupon
    coupon = Coupon.new(:user_id => @test_user.id, :deal_id => deal.id, :order_id => order.id, :deal_code_id => dc.id)
    assert coupon.save
    assert_equal coupon.state, 'Pending'
    # pending - can't view
    get :coupon, :id => coupon.id
    assert_response :redirect
    assert_redirected_to :action=>'home'
    # active - can view
    order.state = Order::PAID
    assert order.save
    coupon = Coupon.find_by_id(coupon.id)
    assert_equal coupon.state, 'Active'
    get :coupon, :id => coupon.id
    assert_response :success
    assert_template "user/coupon"
    # someone else - can't view
    post :login, :email => @empty_user.email, :password => "test"
    assert_response :redirect
    assert_redirected_to :action=>'home'  
    get :coupon, :id => coupon.id
    assert_response :redirect
    assert_redirected_to :action=>'home' 
    # expired - can view
    self.login
    deal.expiration_date = Time.zone.today.end_of_day - 1.days
    assert deal.save
    coupon = Coupon.find_by_id(coupon.id)
    assert_equal coupon.state, 'Expired'
    get :coupon, :id => coupon.id
    assert_response :success
    assert_template "user/coupon"
    # someone else - can't view
    post :login, :email => @empty_user.email, :password => "test"
    assert_response :redirect
    assert_redirected_to :action=>'home'  
    get :coupon, :id => coupon.id
    assert_response :redirect
    assert_redirected_to :action=>'home' 
  end
  
  def test_return_to
    #cant access account without being logged in
    get :account
    assert_response :redirect
    assert_redirected_to :action=>'login'
    assert session[:user_return_to]
    #login
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    #redirected to account
    assert_redirected_to :action=>'account'
    assert_nil session[:user_return_to]
    assert session[:user_id]
    #logout and login again
    get :logout
    assert_nil session[:user_id]
    post :login, :email => @test_user.email, :password => "test"
    assert_response :redirect
    #this time we were redirected to home
    assert_redirected_to :action=>'home'
  end
  
  def test_template_layout
    self.login
    assert_response :redirect
    assert session[:user_id]
    # get correct template and layout
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert_template "layouts/user"
    get :deal, :id => @burger_deal.id
    assert_response :success
    assert_template "user/deal"
    assert_template "layouts/user"
    get :coupons
    assert_response :success
    assert_template 'user/coupons'
    assert_template "layouts/user"
    get :coupon, :id => @burger_coupon1.id
    assert_response :success
    assert_template 'user/coupon'
    assert_template "layouts/user"
    get :login
    assert_response :success
    assert_template 'user/login'
    assert_template "layouts/user"    
  end
  
  def test_visitor
    # cookies are a little strange
    # - can't be access by cookies[:key], needs to be ['key']
    # - always stores value as string
    Visitor.delete_all
    assert_equal Visitor.find(:all).size, 0
    assert_nil session[:visitor_id]
    assert_nil cookies['visitor_id']
    # go to a page (login) - create a visitor
    get :login
    assert session[:visitor_id]
    assert cookies['visitor_id']
    assert_equal Visitor.find(:all).size, 1
    v = Visitor.find_by_id(cookies['visitor_id'])
    assert v
    assert_equal session[:visitor_id], v.id
    assert_equal cookies['visitor_id'].to_i, v.id
    # login - no change
    self.login
    assert session[:visitor_id]
    assert cookies['visitor_id']
    assert_equal Visitor.find(:all).size, 1
    v = Visitor.find_by_id(cookies['visitor_id'])
    assert v
    assert_equal session[:visitor_id], v.id
    assert_equal cookies['visitor_id'].to_i, v.id    
    # go to another page - no change
    get :home
    assert session[:visitor_id]
    assert cookies['visitor_id']
    assert_equal Visitor.find(:all).size, 1
    v = Visitor.find_by_id(cookies['visitor_id'])
    assert v
    assert_equal session[:visitor_id], v.id
    assert_equal cookies['visitor_id'].to_i, v.id    
    # logout - session cleared
    get :logout
    assert_nil session[:visitor_id]
    assert cookies['visitor_id']
    assert_equal Visitor.find(:all).size, 1
    v = Visitor.find_by_id(cookies['visitor_id'])
    assert v
    assert_equal cookies['visitor_id'].to_i, v.id    
    # go to a page (login) - session populated
    get :login
    assert session[:visitor_id]
    assert cookies['visitor_id']
    assert_equal Visitor.find(:all).size, 1
    v = Visitor.find_by_id(cookies['visitor_id'])
    assert v
    assert_equal session[:visitor_id], v.id
    assert_equal cookies['visitor_id'].to_i, v.id    
  end
  
  def test_logging_basic
    Visitor.delete_all
    UserAction.delete_all
    ua = UserAction.find(:first)
    assert_nil ua
    # go to a page (login) - not logged in
    UserAction.delete_all
    get :login
    ua = UserAction.find(:first)
    assert ua
    assert ua.visitor, Visitor.find(:first)
    assert_nil ua.user
    assert_nil ua.merchant
    assert_nil ua.deal
    assert_nil ua.share
    assert_equal ua.controller,  'user'
    assert_equal ua.action, 'login'
    assert_equal ua.method, 'GET'
    # login - won't log - redirected
    UserAction.delete_all
    self.login 
    ua = UserAction.find(:first)
    assert_nil ua
    # go to another page - now have user 
    UserAction.delete_all
    get :deals
    ua = UserAction.find(:first)
    assert ua
    assert ua.visitor, Visitor.find(:first)
    assert_equal ua.user, @test_user
    assert_nil ua.merchant
    assert_nil ua.deal
    assert_nil ua.deal
    assert_equal ua.controller, 'user'
    assert_equal ua.action, 'deals'
    assert_equal ua.method, 'GET'
    # logout - won't log - redirected
    UserAction.delete_all
    get :logout
    ua = UserAction.find(:first)
    assert_nil ua
    # got to another page - no more user
    UserAction.delete_all
    get :deals
    ua = UserAction.find(:first)
    assert ua   
    assert ua.visitor, Visitor.find(:first)
    assert_nil ua.user
    assert_nil ua.merchant
    assert_nil ua.deal
    assert_nil ua.share
    assert_equal ua.controller, 'user'
    assert_equal ua.action, 'deals'
    assert_equal ua.method, 'GET'
  end

  def test_logging_multiple
    UserAction.delete_all
    user_actions = UserAction.find(:all)
    assert_equal user_actions.size, 0
    # go to a page (login) - not logged in
    get :login
    user_actions = UserAction.find(:all)
    assert_equal user_actions.size, 1
    # login - won't log - redirected
    self.login    
    user_actions = UserAction.find(:all)
    assert_equal user_actions.size, 1
    # go to another page
    get :deals
    user_actions = UserAction.find(:all)
    assert_equal user_actions.size, 2
  end

  def test_logging_subdomain
    UserAction.delete_all
    ua = UserAction.find(:first)
    assert_nil ua
    # go to a page (login) - no subdomain
    UserAction.delete_all
    get :login
    ua = UserAction.find(:first)
    assert ua
    assert_nil ua.merchant
    # go to a page (login) - with subdomain
    UserAction.delete_all
    @request.host = @request.host.gsub(/^www\./, "#{@bob.merchant_subdomain.subdomain}.")
    get :login
    ua = UserAction.find(:first)
    assert ua
    assert_equal ua.merchant, @bob   
  end
  
  def test_logging_deal
    UserAction.delete_all
    ua = UserAction.find(:first)
    assert_nil ua
    # go to a non-deal page (login) - no deal id
    UserAction.delete_all
    get :login
    ua = UserAction.find(:first)
    assert ua
    assert_nil ua.deal    
    # go to a deal page
    UserAction.delete_all
    get :deal, :id => @burger_deal.id
    ua = UserAction.find(:first)
    assert ua
    assert_equal ua.deal, @burger_deal
    assert_nil ua.share
    # go to a deal page with share_id
    UserAction.delete_all
    get :deal, :id => @burger_deal.id, :share_id => @burger_share.id
    ua = UserAction.find(:first)
    assert ua
    assert_equal ua.deal, @burger_deal
    assert_equal ua.share, @burger_share 
  end
  
  def test_subdomain_general
    old_host = @request.host
    # go to login - no redirection
    get :login
    assert_response :success
    assert_template "user/login"
    assert_equal @request.host, old_host
    # empty subdomain - redirected
    @request.host = @request.host.gsub(/^www\./, '')
    assert_not_equal @request.host, old_host
    get :login
    assert_response :redirect
    assert_redirected_to :action => :login, :host => old_host    
    # use invalid subdomain - redirected
    @request.host = old_host
    @request.host = @request.host.gsub(/^www\./, 'invalid.')
    assert_not_equal @request.host, old_host
    get :login
    assert_response :redirect
    assert_redirected_to :action => :login, :host => old_host
  end
  
  def test_share
    get :share, :deal_id => @burger_deal.id
    assert_response :redirect
    assert_redirected_to :action => :login
    self.login
    get :share, :deal_id => @burger_deal.id
    assert_response :success
    assert_template "user/share"
    # no deal - go home
    get :share, :deal_id => 0
    assert_response :redirect
    assert_redirected_to :action => :home
    # deal without incentive - go home
    get :share, :deal_id => @current_deal.id
    assert_response :redirect
    assert_redirected_to :action => :home    
  end    
  
  def test_fb_share
    get :fb_share, :deal_id => @burger_deal.id
    assert_response :redirect
    assert_redirected_to :action => :login
    self.login
    # won't have fb requirements
    get :fb_share, :deal_id => @burger_deal.id
    assert_response :redirect
    assert_redirected_to :action => :confirm_permissions, :deal_id => @burger_deal.id
    get :fb_share, :deal_id => 0
    assert_response :redirect
    assert_redirected_to :action => :home
    ### todo - can't do this yet
    # post - not enough facebook_ids
    #post :fb_share, :deal_id => @burger_deal.id, :facebook_ids => [1], :message => 'yo! check this out.'
    #assert_response :redirect
    #assert_redirected_to :action => :fb_share, :deal_id => @burger_deal.id
    # post - enough facebook_ids, but won't have fb_requirements
    #post :fb_share, :deal_id => @burger_deal.id, :facebook_ids => [1,2,3,4,5,6,7,8,9,10], :message => 'yo! check this out.'
    #assert_response :redirect
    #assert_redirected_to :action => :confirm_permissions, :deal_id => @burger_deal.id    
  end
  
=begin  
  def test_create_share
    Share.delete_all
    # not logged in - error
    post :create_share, :deal_id => @burger_deal.id
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "error", json_response['result']
    assert_nil Share.find(:first)
    # login
    self.login 
    # no deal_id - error
    post :create_share
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "error", json_response['result']
    assert_nil Share.find(:first)    
    # ok
    post :create_share, :deal_id => @burger_deal.id
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "success", json_response['result']
    share = Share.find(:first)
    assert share
    assert_equal share.deal_id, @burger_deal.id
    assert_equal share.user_id, @test_user.id
    assert_nil share.post_id
    assert !share.posted
  end
  
  def test_update_share
    self.login
    post :create_share, :deal_id => @burger_deal.id
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "success", json_response['result']
    share = Share.find(:first)
    # no post_id - will pass but no post_id will be saved
    post :update_share, :id => share.id
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "success", json_response['result']
    share = Share.find(:first)
    assert share
    assert_equal share.deal_id, @burger_deal.id
    assert_equal share.user_id, @test_user.id
    assert_nil share.post_id
    assert share.posted
    # ok
    post :update_share, :id => share.id, :post_id => 1234
    assert_response :success
    json_response = ActiveSupport::JSON.decode @response.body
    assert_equal "success", json_response['result']
    share = Share.find(:first)
    assert share
    assert_equal share.deal_id, @burger_deal.id
    assert_equal share.user_id, @test_user.id
    assert_equal share.post_id, "1234"
    assert share.posted
  end
=end
  
end