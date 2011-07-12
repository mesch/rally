require 'test_helper'
require 'facebook_controller'

# Re-raise errors caught by the controller.
class FacebookController; def rescue_action(e) raise e end; end

class FacebookControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :users

  def setup
    @request.host = "www.rcom.com"
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
    # no params - go to deals - host doesn't change
    get :home
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    assert_equal @request.host, old_host 
    # invalid subdomain - go to deals - host doesn't change
    get :home, :sd => 'invalid'
    assert_response :redirect
    assert_redirected_to :action => 'deals'
    assert_equal @request.host, old_host 
    # valid subdomain - host changes
    get :home, :sd => 'bob'
    assert_response :redirect
    assert_redirected_to :action => :home, :host => old_host.gsub(/^www/,'bob')
  end
  
  def test_home_subdomain_no_login
    old_host = @request.host
    assert_nil session[:user_id]
    # no params - go to login - host doesn't change
    get :home
    assert_response :redirect
    assert_redirected_to :action => 'login'
    assert_equal @request.host, old_host 
    # invalid subdomain - go to login - host doesn't change
    get :home, :sd => 'invalid'
    assert_response :redirect
    assert_redirected_to :action => 'login'
    assert_equal @request.host, old_host 
    # valid subdomain - goes to facebook home (due to subdomain redirect) - changes host
    get :home, :sd => 'bob'
    assert_response :redirect
    assert_redirected_to :action => 'home', :host => old_host.gsub(/^www/,'bob')    
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
    assert_equal ua.controller, 'facebook'
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
    assert_equal ua.controller, 'facebook'
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
    assert_equal ua.controller, 'facebook'
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
    @request.host = @request.host.gsub(/^www\./, 'invalid.')
    assert_not_equal @request.host, old_host
    get :login
    assert_response :redirect
    assert_redirected_to :action => :login, :host => old_host
  end
  
end