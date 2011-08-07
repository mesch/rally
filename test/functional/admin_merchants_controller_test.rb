require 'test_helper'
require 'admin/merchants_controller'

# Re-raise errors caught by the controller.
class Admin::MerchantsController; def rescue_action(e) raise e end; end

class Admin::MerchantsControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures = true

  fixtures :merchants
  
  def setup
    @request.host = "www.rcom.com"
    
    @start = Time.zone.today
    @end = Time.zone.today + 1.days
    @expiration = Time.zone.today + 1.months
  end
  
  def test_basic_create
    Merchant.delete_all
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii' }
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'index'
    merchants = Merchant.find(:all)
    assert_equal merchants.size, 1
    assert_equal merchants[0].username, "newbob"
    assert_equal merchants[0].email, "newbob@mcbob.com"
    assert_equal merchants[0].name, "bobs"
    assert merchants[0].active
    assert !merchants[0].activated
    assert !merchants[0].terms
  end

  def test_bad_create
    #check we can't signup if password_confirmation is different
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "wrong", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"   
    
    #check we can't signup without all required fields
    post :create, :merchant => {:username => "", :password => "newpassword", :password_confirmation => "newpassword" , 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"

    #password can't be nil to create the merchant object to being with
    post :create, :merchant => {:username => "newbob", :password => "", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"

    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"
    
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "", :name => 'bobs', :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"
    
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => "", :time_zone => 'Hawaii'}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"
    
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => ""}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"
  end

  def test_create_subdomain
    # subdomain already exists - fail
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :subdomain => "www"}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/new"
    
    # subdomain empty - ok, but no subdomain added
    post :create, :merchant => {:username => "newbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :subdomain => ""}
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'index'
    m = Merchant.find_by_username("newbob")
    assert_nil m.merchant_subdomain
          
    # new subdomain - ok
    post :create, :merchant => {:username => "newnewbob", :password => "newpassword", :password_confirmation => "newpassword", 
      :email => "newbob@mcbob.com", :name => 'bobs', :time_zone => 'Hawaii', :subdomain => "newbob"}
    assert_response :redirect
    assert_nil flash[:error]
    assert_redirected_to :action=>'index'
    m = Merchant.find_by_username("newnewbob")
    assert_equal m.merchant_subdomain.subdomain, "newbob"
  end
  
  def test_change_password
    #passwords dont match
    post :change_password, :id => @bob.id, :password => "newpass", :password_confirmation => "newpassdoesntmatch"
    assert_response :redirect
    assert flash[:error]
    #empty password
    post :change_password, :id => @bob.id, :password => "", :password_confirmation => ""
    assert_response :redirect
    assert flash[:error]
    #success - password changed
    post :change_password, :id => @bob.id, :password => "newpass", :password_confirmation => "newpass"
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'edit'
    assert !Merchant.authenticate(@bob.username, "test")
    assert Merchant.authenticate(@bob.username, "newpass")
  end
  
  def test_change_name
    #name too long
    post :update, :id => @bob.id, :merchant => {:name => '123456789012345678901234567890123456789012345678900', :time_zone => @bob.time_zone}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/edit"
    assert_equal Merchant.find(@bob.id).name, @bob.name
    #success
    post :update, :id => @bob.id, :merchant => {:name => '1234567890', :time_zone => @bob.time_zone}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    assert_equal Merchant.find(@bob.id).name, '1234567890'
  end

  def test_change_email
    #wrong email format
    post :update, :id => @bob.id, :merchant => {:email => "badformat"}
    assert_response :success
    assert flash[:error]
    assert_template "admin/merchants/edit"
    assert_equal Merchant.find(@bob.id).email, @bob.email   
    #success - email changed
    post :update, :id => @bob.id, :merchant => {:email => "test@abc.com"}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    assert_equal Merchant.find(@bob.id).email, "test@abc.com"
  end

  def test_change_subdomain
    #assuming existingbob doesn't have subdomain set
    # no subdomain set
    m = Merchant.find_by_id(@existingbob.id)
    assert_nil m.merchant_subdomain
    # empty subdomain - do nothing
    post :update, :id => @existingbob.id, :merchant => {:subdomain => ""}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    m = Merchant.find_by_id(@existingbob.id)
    assert_nil m.merchant_subdomain
    # taken subdomain - fail
    post :update, :id => @existingbob.id, :merchant => {:subdomain => "www"}
    assert_response :success
    assert flash[:error]
    m = Merchant.find_by_id(@existingbob.id)
    assert_nil m.merchant_subdomain
    # new subdomain - save
    post :update, :id => @existingbob.id, :merchant => {:subdomain => "existingbob"}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    m = Merchant.find_by_id(@existingbob.id)
    assert m.merchant_subdomain.subdomain, "existingbob"
    # same subdomain - do nothing
    post :update, :id => @existingbob.id, :merchant => {:subdomain => "existingbob"}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    m = Merchant.find_by_id(@existingbob.id)
    assert m.merchant_subdomain.subdomain, "existingbob"
    # empty subdomain - do nothing (for now?)
    post :update, :id => @existingbob.id, :merchant => {:subdomain => ""}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    m = Merchant.find_by_id(@existingbob.id)
    assert m.merchant_subdomain.subdomain, "existingbob"
  end

  # can change time zone after creation
  def test_change_time_zone
    assert_not_equal Merchant.find(@bob.id).time_zone, 'Hawaii'
    post :update, :id => @bob.id, :merchant => {:time_zone => "Hawaii"}
    assert_response :redirect
    assert flash[:notice]
    assert_redirected_to :action => 'index'
    assert_equal Merchant.find(@bob.id).time_zone, 'Hawaii'
  end
  
  def test_impersonate
    get :impersonate, :id => @bob.id
    assert_response :redirect
    assert_redirected_to :controller => "/merchant", :action => :home
    assert_equal session[:merchant_id], @bob.id
  end
  
end