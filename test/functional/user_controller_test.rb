require 'test_helper'
require 'user_controller'

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :users

  def setup
    @controller = UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "localhost"
  end

  def login
    post :login, :username => @test_user.username, :password => "test"
  end

  def test_auth
    #check we can login
    # valid username
    post :login, :username => @test_user.username, :password => "test"
    assert session[:user_id]
    assert_equal @test_user, User.find(session[:user_id])
    assert_response :redirect
    assert_redirected_to :action=>'home'
    # valid email
    post :login, :username => @test_user.email, :password => "test"
    assert session[:user_id]
    assert_equal @test_user, User.find(session[:user_id])
    assert_response :redirect
    assert_redirected_to :action=>'home'    
  end

  def test_set_time_zone
    old_time_zone = Time.zone.name
    # Time zone should be different than local time (as set in users.yml)
    post :login, :username => @existing_user.username, :password => "test"
    get :home
    assert_equal Time.zone.name, @existing_user.time_zone
    assert_not_equal Time.zone.name, old_time_zone
  end

  def test_signup
    #unfortunately can't test passing captcha - this will fail for now
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", :email => "newbob@mcbob.com" 
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/signup"
  end

  def test_bad_signup
    #check we can't signup without all required fields
    post :signup, :username => "newbob", :password => "newpassword", :password_confirmation => "wrong" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "user/signup"
    assert_nil session[:user_id]

    post :signup, :username => "yo", :password => "newpassword", :password_confirmation => "newpassword" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "user/signup"
    assert_nil session[:user_id]

    post :signup, :username => "yo", :password => "newpassword", :password_confirmation => "wrong" , :email => "newbob@mcbob.com"
    assert_response :success
    assert_template "user/signup"
    assert_nil session[:user_id]
  end

  def test_invalid_login
    #can't login with incorrect password
    post :login, :username => @test_user.username, :password => "not_correct"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/login"
  end

  def test_inactive_login
    #can't login if user is not active
    post :login, :username => @inactive_user.username, :password => "test"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/login"
  end

  def test_inactivated_login
    #redirected to activate account
    post :login, :username => @inactivated_user.username, :password => "test"
    assert_response :redirect
    assert_nil session[:user_id]
    assert flash[:error]
    assert_redirected_to :action=>'reactivate'
  end

  def test_login_logoff
    #login
    post :login, :username => @test_user.username, :password => "test"
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
    post :login, :username => @test_user.username, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #logout
    get :logout
    assert_response :redirect
    assert_nil session[:user_id]
    #enter a username (or email) that doesn't exist
    post :forgot_password, :username => "testtesttest"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/forgot_password"
    #enter a username that doesn't exist
    post :forgot_password, :username => "testtesttest"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/forgot_password"
    #enter an email that doesn't exist
    post :forgot_password, :username => "notauser@doesntexist.com"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    assert_template "user/forgot_password"
    #enter valid username
    post :forgot_password, :username => @test_user.username   
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
    #enter valid email
    post :forgot_password, :username => @test_user.email 
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
    post :login, :username => @test_user.username, :password => "test"
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
    post :login, :username => @test_user.username, :password => "test"
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
    post :login, :username => @test_user.username, :password => "test"
    assert_response :success
    assert_nil session[:user_id]
    assert flash[:error]
    #new password works
    post :login, :username => @test_user.username, :password => "newpass"
    assert_response :redirect
    assert session[:user_id]
  end

  def test_reactivate_email
    #email sent from reactivate page
    #enter a username that doesn't exist
    post :reactivate, :username => "testertesterson"
    assert_response :success
    assert_nil session[:user_id]
    assert_template "user/reactivate"
    assert flash[:error]
    #enter an email that doesn't exist
    post :reactivate, :username => "test@abc.com"
    assert_response :success
    assert_nil session[:user_id]
    assert_template "user/reactivate"
    assert flash[:error]
    #enter an activated username
    post :reactivate, :username => @test_user.username
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
    #enter an activated email
    post :reactivate, :username => @test_user.email
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'  
    #enter an inactivated username
    post :reactivate, :username => @inactivated_user.username
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
    #enter an inactivated email
    post :reactivate, :username => @inactivated_user.email
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
    post :login, :username => @test_user.username, :password => "test"
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
    post :forgot_password, :username => old_email
    assert_response :success
    assert flash[:error]
    assert_template "user/forgot_password"
    #can find new email
    post :forgot_password, :username=>"test@abc.com"   
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action=>'login'
  end

  def test_change_account_basic
    #just changing name
    #can login
    post :login, :username => @test_user.username, :password => "test"
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
    post :login, :username => @test_user.username, :password => "test"
    assert_response :redirect
    assert session[:user_id]
    #success
    post :account, :first_name => 'tester', :last_name => 'testerson', :mobile_number => '4155551213'
    assert_response :success
    assert flash[:notice]
    assert_template "user/account"
    assert_equal User.find(@test_user.id).first_name, 'tester'
    assert_equal User.find(@test_user.id).last_name, 'testerson'
    assert_equal User.find(@test_user.id).mobile_number, '4155551213'
  end

  # cannot change time zone for user (yet)
  def test_change_time_zone
    #can login
    post :login, :username => @test_user.username, :password => "test"
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

## unable to test due to @request not getting set in ApplicationController
=begin
  def test_return_to
    #cant access account without being logged in
    get :account
    assert_response :redirect
    assert_redirected_to :action=>'login'
    assert session[:user_return_to]
    #login
    post :login, :username => @test_user.username, :password => "test"
    assert_response :redirect
    #redirected to account
    assert_redirected_to :action=>'account'
    assert_nil session[:user_return_to]
    assert session[:user_id]
    assert flash[:notice]
    #logout and login again
    get :logout
    assert_nil session[:user_id]
    post :login, :username => @test_user.username, :password => "test"
    assert_response :redirect
    #this time we were redirected to home
    assert_redirected_to :action=>'home'
  end
=end
end