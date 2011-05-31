require 'test_helper'

class CouponTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :coupons

  def setup
    Coupon.delete_all
    @m = Merchant.find(:first)
    @start = Time.zone.today
    @end = Time.zone.today + 1.days
    @expiration = Time.zone.today + 1.months
  end
  
  def test_coupon_create_basic
    c = Coupon.new(:user_id => 1000, :deal_id => 1, :order_id => 3, :deal_code_id => 100)
    assert c.save
    # check id is protected
    old_id = c.id
    c.id = old_id+1
    assert c.save
    c = Coupon.find(old_id)
    assert_equal c.id, old_id
  end
  
  def test_coupon_create_multiple
    c = Coupon.new(:user_id => 1000, :deal_id => 1, :order_id => 3, :deal_code_id => 100)
    assert c.save
    # same user_id, same deal_id, same deal_code_id, same order_id - ok (for now, ideally deal_code would be better handled)
    c = Coupon.new(:user_id => 1000, :deal_id => 1, :deal_code_id => 100, :order_id => 3)
    assert c.save        
  end
  
  def test_coupon_missing_fields
    c = Coupon.new(:user_id => nil, :deal_id => 1, :order_id => 3, :deal_code_id => 100)
    assert !c.save
    c = Coupon.new(:user_id => 1000, :deal_id => nil, :order_id => 3, :deal_code_id => 100)
    assert !c.save
    c = Coupon.new(:user_id => 1000, :deal_id => 1, :order_id => nil, :deal_code_id => 100)
    assert !c.save    
    # ok without deal_code_id
    c = Coupon.new(:user_id => 1000, :deal_id => 1, :order_id => 3, :deal_code_id => nil)
    assert c.save
  end

  def test_state
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => Time.zone.today, :end_date => Time.zone.today, 
      :expiration_date => Time.zone.today, :deal_price => '10.00', :deal_value => '20.00', :min => 2)
    assert d.save
    # add an authorized order
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => OPTIONS[:order_states][:authorized])
    assert o.save
    # with a coupon
    c = Coupon.new(:user_id => 1, :deal_id => d.id, :order_id => o.id)
    assert c.save
    assert !d.is_expired
    assert !d.is_tipped
    assert_equal c.state, "Pending"
    # tipping the deal - should still be pending
    d.update_attributes(:min => 1)
    assert d.is_tipped
    c = Coupon.find_by_id(c.id)
    assert_equal c.state, "Pending"
    # expire the deal - should be expired
    d.update_attributes(:expiration_date => Time.zone.today - 1.days)
    assert d.is_expired
    c = Coupon.find_by_id(c.id)
    assert_equal c.state, "Expired"
    # the order gets paid - should be "Active"
    d.update_attributes(:expiration_date => Time.zone.today)
    assert !d.is_expired
    o.update_attributes(:state => OPTIONS[:order_states][:paid])
    c = Coupon.find_by_id(c.id)
    assert_equal c.state, "Active"
    # expire the deal - should be expired
    d.update_attributes(:expiration_date => Time.zone.today - 1.days)
    assert d.is_expired
    c = Coupon.find_by_id(c.id)
    assert_equal c.state, "Expired"
  end

end
