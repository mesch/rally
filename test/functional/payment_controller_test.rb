require 'test_helper'
require 'payment_controller'

# Re-raise errors caught by the controller.
class PaymentController; def rescue_action(e) raise e end; end

class PaymentControllerTest < ActionController::TestCase

  self.use_instantiated_fixtures  = true

  fixtures :users
  fixtures :deals

  def setup
    @controller = PaymentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "localhost"
    
    @deal = @burger_deal
    @order = @test_user.unconfirmed_order(@deal.id)
    @order.update_attributes(:quantity => '1', :amount => '20.00')
  end

  def login
    @controller = UserController.new
    post :login, :email => @test_user.email, :password => "test"
    @controller = PaymentController.new
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
    assert_redirected_to :controller => 'user', :action=>'login'
  end
  
  def test_order_no_deal_id
    self.login
    get :order
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
  end
  
  def test_order_no_existing_deal
    self.login
    get :order, :deal_id => 0
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
  end

  def test_order_deal_ended
    @deal.update_attributes(:end_date => Time.zone.today - 1.days)
    assert @deal.is_ended
    self.login
    get :order, :deal_id => @deal.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'    
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
    assert_redirected_to :controller => 'user', :action=>'login'
  end
  
  def test_purchase_no_order_id
    self.login
    get :purchase
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
  end
  
  def test_purchase_no_existing_order
    self.login
    get :purchase, :order_id => 0
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
  end  

  def test_purchase_confirmed_order
    # authorized
    @order.update_attributes(:state => OPTIONS[:order_states][:authorized])
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
    # paid
    @order.update_attributes(:state => OPTIONS[:order_states][:paid])
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'     
  end
  
  def test_purchase_empty_order
    # zero quantity, zero amount - fail
    @order.update_attributes(:quantity => '0', :amount => '0')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
    # zero quantity, some amount (shouldn't happen) - fail    
    @order.update_attributes(:quantity => '0', :amount => '10.00')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'
    # some quantity, zero amount (shouldn't happen) - fail
    @order.update_attributes(:quantity => '1', :amount => '0')
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'      
  end

  def test_purchase_deal_ended
    @deal.update_attributes(:end_date => Time.zone.today - 1.days)
    assert @deal.is_ended
    self.login
    get :purchase, :order_id => @order.id
    assert_response :redirect
    assert_redirected_to :controller => 'user', :action=>'home'    
  end

end