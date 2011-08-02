require 'test_helper'
require 'facebook_payment_controller'

# Re-raise errors caught by the controller.
class FacebookPaymentController; def rescue_action(e) raise e end; end

class FacebookPaymentControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :users
  fixtures :deals

  def setup
    @request.host = "www.rcom.com"
    
    @deal = @burger_deal
    @order = @test_user.unconfirmed_order(@deal.id)
    @order.update_attributes(:quantity => '1', :amount => '20.00')
    @user_controller_name = 'facebook'   
  end

  def login
    # faking FB login for now
    @controller = UserController.new
    post :login, :email => @test_user.email, :password => "test"
    @controller = FacebookPaymentController.new
  end
  
  # order page
  def test_order_basic
    self.login
    get :order, :deal_id => @deal.id
    assert_response :success
    assert_template "payment/order"
  end
  
  def test_order_no_login
    get :order, :deal_id => @deal.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'login'
  end
  
  def test_order_no_deal_id
    self.login
    get :order
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
  end
  
  def test_order_no_existing_deal
    self.login
    get :order, :deal_id => 0
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
  end

  def test_order_deal_ended
    @deal.update_attributes(:end_date => Time.zone.today - 1.days)
    assert @deal.is_ended
    self.login
    get :order, :deal_id => @deal.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'    
  end  
  
  # purchase page
  def test_purchase_basic
    self.login
    get :purchase, :order_id => @order.id
    assert_response :success
    assert_template "payment/purchase"
  end
  
  def test_purchase_no_login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'login'
  end
  
  def test_purchase_no_order_id
    self.login
    get :purchase
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
  end
  
  def test_purchase_no_existing_order
    self.login
    get :purchase, :order_id => 0
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
  end  

  def test_purchase_confirmed_order
    # authorized
    @order.update_attributes(:state => Order::AUTHORIZED)
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
    # paid
    @order.update_attributes(:state => Order::PAID)
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'     
  end
  
  def test_purchase_empty_order
    # zero quantity, zero amount - fail
    @order.update_attributes(:quantity => '0', :amount => '0')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
    # zero quantity, some amount (shouldn't happen) - fail    
    @order.update_attributes(:quantity => '0', :amount => '10.00')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'
    # some quantity, zero amount (shouldn't happen) - fail
    @order.update_attributes(:quantity => '1', :amount => '0')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'      
  end

  def test_purchase_deal_ended
    @deal.update_attributes(:end_date => Time.zone.today - 1.days)
    assert @deal.is_ended
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => @user_controller_name, :action=>'home'    
  end

  def test_logging_deal
    Visitor.delete_all
    self.login
    UserAction.delete_all
    ua = UserAction.find(:first)
    assert_nil ua 
    # go to order page
    Order.delete_all
    UserAction.delete_all
    get :order, :deal_id => @deal.id
    ua = UserAction.find(:first)
    assert ua
    assert ua.visitor, Visitor.find(:first)
    assert_equal ua.user, @test_user
    assert_nil ua.merchant
    assert_equal ua.deal, @deal
    assert_equal ua.controller, 'facebook_payment'
    assert_equal ua.action, 'order'
    assert_equal ua.method, 'GET'
    # complete order 
    post :order, :deal_id => @deal.id, :quantity => 1
    # go to payment page
    UserAction.delete_all
    get :purchase, :order_id => Order.find(:first).id
    ua = UserAction.find(:first)
    assert ua    
    assert ua.visitor, Visitor.find(:first)
    assert_equal ua.user, @test_user
    assert_nil ua.merchant
    assert_equal ua.deal, @deal
    assert_equal ua.controller, 'facebook_payment'
    assert_equal ua.action, 'purchase'
    assert_equal ua.method, 'GET'
    # go to receipt page
    UserAction.delete_all
    get :receipt, :gateway => OPTIONS[:gateways][:authorize_net], :x_invoice_num => Order.find(:first).id,
      :x_type => 'AUTHORIZE', :x_amount => '10.00', :x_auth_code => 'xyz123'
    ua = UserAction.find(:first)
    assert ua
    assert ua.visitor, Visitor.find(:first)
    assert_equal ua.user, @test_user
    assert_nil ua.merchant
    assert_equal ua.deal, @deal
    assert_equal ua.controller, 'facebook_payment'
    assert_equal ua.action, 'receipt'
    assert_equal ua.method, 'GET'
  end

  def test_logging_subdomain
    Visitor.delete_all
    self.login
    UserAction.delete_all
    ua = UserAction.find(:first)
    assert_nil ua
    # go to an order page - no subdomain
    UserAction.delete_all
    get :order, :deal_id => @burger_deal.id
    ua = UserAction.find(:first)
    assert ua
    assert_nil ua.merchant
    # go to an order page - with subdomain
    UserAction.delete_all
    @request.host = @request.host.gsub(/^www\./, "#{@bob.merchant_subdomain.subdomain}.")
    get :order, :deal_id => @burger_deal.id
    ua = UserAction.find(:first)
    assert ua
    assert_equal ua.merchant, @bob   
  end

end