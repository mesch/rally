require 'test_helper'
require 'facebook_controller'

# Re-raise errors caught by the controller.
class FacebookController; def rescue_action(e) raise e end; end

class FacebookControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :users

  def setup
    @request.host = "rc.com"
  end

  def login(user=@test_user)
    # faking FB login for now
    @controller = UserController.new
    post :login, :email => user.email, :password => "test"
    @controller = FacebookController.new
  end

  def test_set_time_zone
    old_time_zone = Time.zone.name
    # Time zone should be different than local time (as set in users.yml)
    self.login(@existing_user)
    get :home
    assert_equal Time.zone.name, @existing_user.time_zone
    assert_not_equal Time.zone.name, old_time_zone
  end

  def test_inactive_login
    #can't login if user is not active
    self.login(@inactive_user)
    assert_nil session[:user_id]
  end

  def test_template_layout
    self.login
    assert_response :redirect
    assert session[:user_id]
    # get correct template and layout
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert_template "layouts/facebook"
    get :deal, :id => Deal.find(:first).id
    assert_response :success
    assert_template "user/deal"
    assert_template "layouts/facebook"
    get :coupons
    assert_response :success
    assert_template 'user/coupons'
    assert_template "layouts/facebook"
    get :coupon, :id => @test_user.coupons[0]
    assert_response :success
    assert_template 'user/coupon'
    assert_template "layouts/facebook"
    get :login
    assert_response :success
    assert_template 'user/login'
    assert_template "layouts/facebook"    
  end

  def test_login_required
    #can't access coupons page if not logged in
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'login'
    get :coupons
    assert_response :redirect
    assert_redirected_to :action=>'login'
    get :coupon, :id => @test_user.coupons[0]
    assert_response :redirect
    assert_redirected_to :action=>'login'
    #login
    self.login
    assert_response :redirect
    assert session[:user_id]
    #can access it now
    get :home
    assert_response :redirect
    assert_redirected_to :action=>'deals'
    get :coupons
    assert_response :success
    assert_template 'user/coupons'
    get :coupon, :id => @test_user.coupons[0]
    assert_response :success
    assert_template 'user/coupon'    
  end

  def test_login_not_required
    # can access the deals and deal pages without logging in (but session isn't set)
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert_nil session[:user_id]
    get :deal, :id => Deal.find(:first).id
    assert_response :success
    assert_template "user/deal"
    assert_nil session[:user_id]
    get :splash
    assert_response :success
    assert_template "facebook/splash"
    assert_nil session[:user_id]     
    # session will be set if we login first
    self.login
    assert_response :redirect
    assert session[:user_id]
    # can still access
    get :deals
    assert_response :success
    assert_template "user/deals"
    assert session[:user_id]
    get :deal, :id => Deal.find(:first).id
    assert_response :success
    assert_template "user/deal"
    assert session[:user_id]
    get :splash
    assert_response :success
    assert_template "facebook/splash"
    assert session[:user_id]
  end
  
  def test_home_subdomain
    old_host = @request.host
    self.login
    assert_response :redirect
    assert session[:user_id]
    # no params - go to deals
    get :home
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    # invalid subdomain - host doesn't change
    get :home, :sd => 'testing'
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    assert_equal @request.host, old_host 
    # invalid subdomain - host doesn't change
    get :home, :sd => 'bob'
    assert_response :redirect
    assert_redirected_to :action => :home, :host => "bob.#{old_host}"
  end
  
  def test_home_fb_page_id
    self.login
    assert_response :redirect
    assert session[:user_id]
    # no params - go to deals
    get :home
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    # fb_page_id already configured for a client - still goes to deals
    get :home, :fb_page_id => @bob.facebook_page_id
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    # new fb_page_id - go to merchant connect
    get :home, :fb_page_id => 0
    assert_response :redirect
    assert_redirected_to :controller => 'merchant', :action => 'connect', :fb_page_id => 0    
  end
  
end