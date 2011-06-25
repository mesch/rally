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
    assert o.state = OPTIONS[:order_states][:created]
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
  
  def test_order_state_enum
    o = Order.new(:user_id => 1000, :deal_id => 1, :state => OPTIONS[:order_states][:created])
    assert o.save
    o.state = 'SOMETHING_ELSE'
    assert !o.save
    o = Order.new(:user_id => 1000, :deal_id => 1, :state => OPTIONS[:order_states][:authorized])
    assert o.save
    o = Order.new(:user_id => 1000, :deal_id => 1, :state => OPTIONS[:order_states][:paid])
    assert o.save
    o = Order.new(:user_id => 1000, :deal_id => 1, :state => 'SOMETHING_ELSE')
    assert !o.save
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
  
  def test_reserve_quantity
    Deal.delete_all
    Order.delete_all
    d = Deal.new(:merchant_id => @bob.id, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00', :max => 2)
    assert d.save
    assert_equal d.coupon_count, 0
    # new order for the deal - ok
    o = Order.new(:user_id => 1, :deal_id => d.id)
    assert o.save
    old_updated_at = o.updated_at
    sleep(0.001)
    assert o.reserve_quantity(1)
    assert o.updated_at > old_updated_at
    assert_equal o.quantity, 1
    assert_equal o.amount, 10.to_money 
    assert_equal d.coupon_count, 1
    # update quantity to 2 - ok
    assert o.reserve_quantity(2)
    assert_equal o.quantity, 2
    assert_equal o.amount, 20.to_money 
    assert_equal d.coupon_count, 2
    # set quantity back to 1 - ok
    assert o.reserve_quantity(1)
    assert_equal o.quantity, 1
    assert_equal o.amount, 10.to_money 
    assert_equal d.coupon_count, 1
    # add another order with quantity of 1 - ok
    o = Order.new(:user_id => 1, :deal_id => d.id)
    assert o.save
    assert o.reserve_quantity(1)
    assert_equal o.quantity, 1
    assert_equal o.amount, 10.to_money 
    assert_equal d.coupon_count, 2
    # update quantity to 2 - fail
    assert !o.reserve_quantity(2)
    assert_equal o.quantity, 1
    assert_equal o.amount, 10.to_money 
    assert_equal d.coupon_count, 2
    # add another order with quantity of 1 - fail
    o = Order.new(:user_id => 1, :deal_id => d.id)
    assert o.save
    assert !o.reserve_quantity(1)
    assert_equal o.quantity, 0
    assert_equal o.amount, 0.to_money 
    assert_equal d.coupon_count, 2
  end
  
  # leaving maxed out checks to testing of reserve_coupons
  def test_create_coupons
    # create user
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    # create deal
    d = Deal.new(:merchant_id => 1000, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00', :max => 10)
    assert d.save
    # create order with single quantity
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.save
    assert o.reserve_quantity(1)
    assert o.create_coupons!
    coupons = Coupon.find(:all, :conditions => ["user_id = ? AND deal_id = ? AND order_id = ?", u.id, d.id, o.id])
    assert_equal coupons.size, 1
    assert_equal coupons[0].deal_code, nil
    # create order with multiple quantity
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.save
    assert o.reserve_quantity(2)
    assert o.create_coupons!
    coupons = Coupon.find(:all, :conditions => ["user_id = ? AND deal_id = ? AND order_id = ?", u.id, d.id, o.id])
    assert_equal coupons.size, 2
    assert_equal coupons[0].deal_code, nil
    assert_equal coupons[1].deal_code, nil       
    # create new deal
    d = Deal.new(:merchant_id => 1001, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00', :max => 10)
    assert d.save
    # add a deal code
    dc = DealCode.new(:deal_id => d.id, :code => 'a')
    assert dc.save
    assert !dc.reserved
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.save
    assert o.reserve_quantity(1)
    assert o.create_coupons!
    coupons = Coupon.find(:all, :conditions => ["user_id = ? AND deal_id = ? AND order_id = ?", u.id, d.id, o.id])
    assert_equal coupons.size, 1
    assert_equal coupons[0].deal_code.code, 'a'
    dc = DealCode.find(coupons[0].deal_code_id)
    assert dc.reserved
    # add more deal codes
    dc = DealCode.new(:deal_id => d.id, :code => 'b')
    assert dc.save
    dc = DealCode.new(:deal_id => d.id, :code => 'c')
    assert dc.save
    # create order with multiple quantity
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.save
    assert o.reserve_quantity(2)
    assert o.create_coupons!
    coupons = Coupon.find(:all, :conditions => ["user_id = ? AND deal_id = ? AND order_id = ?", u.id, d.id, o.id])
    assert_equal coupons.size, 2
    assert_equal coupons[0].deal_code.code, 'b'
    dc = DealCode.find(coupons[0].deal_code_id)
    assert dc.reserved
    assert_equal coupons[1].deal_code.code, 'c'
    dc = DealCode.find(coupons[1].deal_code_id)
    assert dc.reserved
  end

  def test_process_authorization
    # create user
    u = User.new(:email => "test@abc.com", :salt => "1000", :activation_code => "1234")
    u.password = u.password_confirmation = "bobs_secure_password"
    assert u.save
    # create deal
    d = Deal.new(:merchant_id => 1000, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00', :max => 10)
    assert d.save
    # create order with single quantity
    o = Order.new(:user_id => u.id, :deal_id => d.id)
    assert o.save
    assert o.state = OPTIONS[:order_states][:created]
    assert !o.authorized_at
    assert o.reserve_quantity(1)
    assert o.process_authorization(:gateway => 'authorize_net', :transaction_type => 'auth_only', :amount => '10.00', 
      :confirmation_code => 'XYZ123')
    coupons = Coupon.find(:all, :conditions => ["user_id = ? AND deal_id = ? AND order_id = ?", u.id, d.id, o.id])
    assert_equal coupons.size, 1
    ops = OrderPayment.find(:all, :conditions => ["user_id = ? AND order_id = ?", u.id, o.id])
    assert_equal ops.size, 1
    assert_equal ops[0].gateway, 'authorize_net'
    assert_equal ops[0].transaction_type, 'auth_only'
    assert_equal ops[0].amount, 10.to_money
    assert_equal ops[0].confirmation_code, 'XYZ123'
    assert o.state = OPTIONS[:order_states][:authorized]
    assert o.authorized_at
    # can't be missing any fields in the method call
    assert !o.process_authorization(:gateway => nil, :transaction_type => 'auth_only', :amount => '10.00', 
      :confirmation_code => 'XYZ123')
    assert !o.process_authorization(:gateway => 'authorize_net', :transaction_type => 'auth_only', :amount => nil, 
      :confirmation_code => 'XYZ123')
    # ok to be missing these fields? for now ...
    assert o.process_authorization(:gateway => 'authorize_net', :transaction_type => nil, :amount => '10.00', 
        :confirmation_code => 'XYZ123')
    assert o.process_authorization(:gateway => 'authorize_net', :transaction_type => 'auth_only', :amount => '10.00', 
      :confirmation_code => nil)
  end
  
  def test_is_timed_out
    timeout = 0.001
    o = Order.new(:user_id => 1, :deal_id => 10)
    assert o.save
    old_updated_at = o.updated_at
    sleep(timeout)
    assert o.is_timed_out(timeout)
    assert o.updated_at > old_updated_at
  end
  
  def test_reset_orders
    Order.delete_all
    o = Order.new(:user_id => 1, :deal_id => 10, :quantity => 1, :amount => "10.00")
    assert o.save
    # should remain - still within default timeout
    Order.reset_orders
    o = Order.find_by_id(o.id)
    assert_equal o.quantity, 1
    timeout = 0.001
    # will be reset
    sleep(timeout+1)
    Order.reset_orders(timeout)
    o = Order.find_by_id(o.id)
    assert_equal o.quantity, 0
    o = Order.new(:user_id => 1, :deal_id => 10, :quantity => 1, :amount => "10.00", :state => OPTIONS[:order_states][:authorized])
    o.save
    # should remain - is confirmed
    sleep(timeout+1)
    Order.reset_orders(timeout)
    o = Order.find_by_id(o.id)
    assert_equal o.quantity, 1
  end
  
end
