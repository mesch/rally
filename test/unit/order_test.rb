require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :orders

  def setup
    Order.delete_all
  end
  
  def test_order_create_basic
    o = Order.new(:user_id => 1000, :deal_id => 1)
    assert o.quantity, 0
    o.quantity = 3
    assert o.save
    assert_equal o.quantity, 3
    assert_equal o.amount, 0.to_money
    o.amount = '60.00'
    assert o.save
    assert_equal o.quantity, 3
    assert_equal o.amount, 60.to_money    
    # check id is protected
    old_id = o.id
    o.id = old_id+1
    assert o.save
    o = Order.find(old_id)
    assert_equal o.id, old_id
  end  
  
  def test_order_create_multiple
    o = Order.new(:user_id => 1000, :deal_id => 1)
    assert o.save
    # same user_id, same deal_id, default quantity, default amount - ok
    o = Order.new(:user_id => 1000, :deal_id => 1)
    assert o.save
    o = Order.new(:user_id => 1000, :deal_id => 1, :quantity => 1, :amount => '60.00')
    assert o.save
    # same user_id, same deal_id, same quantity, same amount - ok
    o = Order.new(:user_id => 1000, :deal_id => 1, :quantity => 1, :amount => '60.00')
    assert o.save       
  end
  
  def test_order_image_missing_fields
    o = Order.new(:user_id => nil, :deal_id => 1, :quantity => 3, :amount => '60.00')
    assert !o.save
    o = Order.new(:user_id => 1000, :deal_id => nil, :quantity => 3, :amount => '60.00')
    assert !o.save
    o = Order.new(:user_id => 1000, :deal_id => 1, :quantity => nil, :amount => '60.00')
    assert !o.save    
    o = Order.new(:user_id => 1000, :deal_id => 1, :quantity => 3, :amount => nil)
    assert !o.save
  end
  
end
