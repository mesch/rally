require 'test_helper'

class CouponTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :coupons

  def setup
    Coupon.delete_all
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

end
