require 'test_helper'

class OrderPaymentTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true

  def setup
    OrderPayment.delete_all
  end
  
  def test_payment_create_basic
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert op.save
    # check id is protected
    old_id = op.id
    op.id = old_id+1
    assert op.save
    op = OrderPayment.find(old_id)
    assert_equal op.id, old_id
  end
  
  def test_payment_create_multiple
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert op.save
    # same record - ok (for now?)
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert op.save       
  end
  
  def test_payment_missing_fields
    op = OrderPayment.new(:user_id => nil, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert !op.save    
    op = OrderPayment.new(:user_id => 1, :order_id => nil, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert !op.save
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => nil, :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert !op.save
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => nil)
    assert !op.save
    # missing transaction_type, confirmation_code or transaction_id - ok
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => nil, :transaction_id => '1234', :amount => '20.00')
    assert op.save
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => nil, 
      :confirmation_code => 'XYZ123', :transaction_id => '1234', :amount => '20.00')
    assert op.save
    op = OrderPayment.new(:user_id => 1, :order_id => 10, :gateway => OPTIONS[:gateways][:authorize_net], :transaction_type => 'AUTH_ONLY', 
      :confirmation_code => 'XYZ123', :transaction_id => nil, :amount => '20.00')
    assert op.save
  end

end
