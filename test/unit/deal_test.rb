require 'test_helper'

class DealTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deals
  
  def setup
    @m = @emptybob
    @start = Time.zone.today.beginning_of_day
    @end = Time.zone.today.end_of_day + 1.days
    @expiration = Time.zone.today.end_of_day + 1.months
  end

  def test_create_basic
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    # check defaults
    assert d.active
    assert_equal d.max, 0
    assert_equal d.limit, 1
    assert !d.published
    # check money fields
    assert_equal d.deal_price, 10.00
    assert_equal d.deal_value, 20.00
    assert d.save
    # check id is protected
    old_id = d.id
    d.id = old_id+1
    assert d.save
    d = Deal.find(old_id)
    assert d
    assert_equal d.id, old_id
  end
  
  def test_ranges
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.min = -1
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.max = -1
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.limit = -1
    assert !d.save
  end
  
  def test_empty_fields
    # should fail
    d = Deal.new(:merchant_id => @m.id, :title => '', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
  end
  
  def test_missing_fields
    d = Deal.new(:merchant_id => nil, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => nil, :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => nil, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => nil, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => nil, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => nil, :deal_value => '20.00')
    assert !d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => nil)
    assert !d.save
  end
  
  def test_create_full
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.min = 10
    d.max = 100
    d.limit = 5
    d.description = 'blahblah'
    d.terms = 'limited to blah.'
    d.active = false
    assert d.save
    # check defaults
    assert_not_equal d.max, 0
    assert_not_equal d.limit, 1
    assert !d.active
  end
  
  def test_create_multiple
    # No uniqueness constraints - can create same deal twice
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
  end
  
  def test_field_lengths
    # title - 100 chars
    string = ""
    length = 101
    length.times{ string << "a"}
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.title = string
    assert !d.save
    # description - 2000 chars
    string = ""
    length = 2001
    length.times{ string << "a"}
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.description = string
    assert !d.save
    # terms - 2000 chars
    string = ""
    length = 2001
    length.times{ string << "a"}
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.terms = string
    assert !d.save
  end
  
  def test_discount_savings
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
       
    assert_equal d.discount, 50
    assert_equal d.savings, 10.to_money    
    # deal_value = 0
    d.deal_value = 0
    d.deal_price = 10
    assert_equal d.discount, 0
    assert_equal d.savings, -10.to_money    
    # deal_price = 0
    d.deal_value = 20
    d.deal_price = 0
    assert_equal d.discount, 100
    assert_equal d.savings, 20.to_money
    # both = 0
    d.deal_value = 0
    d.deal_price = 0
    assert_equal d.discount, 0
    assert_equal d.savings, 0.to_money    
  end

  def test_coupon_count
    Order.delete_all
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal d.coupon_count, 0
    # order with no quantity - no change
    o = Order.new(:user_id => 1, :deal_id => d.id)
    assert o.save
    assert_equal d.coupon_count, 0
    # update order with 1 quantity - +1 count
    o.quantity = 1
    o.amount = '10'
    assert o.save
    assert_equal d.coupon_count, 1
    # update order as authorized - no change
    o.state = Order::AUTHORIZED
    assert o.save
    assert_equal d.coupon_count, 1
    # update order as paid - no change
    o.state = Order::PAID
    assert o.save
    assert_equal d.coupon_count, 1
    # order with different deal_id with no quantity - no change
    o = Order.new(:user_id => 1, :deal_id => d.id+1)
    assert o.save
    assert_equal d.coupon_count, 1
    # order with different deal_id with 1 quantity - no change
    o.quantity = 1
    o.amount = '10'
    assert o.save
    assert_equal d.coupon_count, 1
    # order with new user_id with 2 quantity - +2 count
    o = Order.new(:user_id => 2, :deal_id => d.id, :quantity => 2, :amount => '20')
    assert o.save
    assert_equal d.coupon_count, 3  
  end
  
  def test_confirmed_coupon_count
    Order.delete_all
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal d.confirmed_coupon_count, 0
    # order with no quantity - no change
    o = Order.new(:user_id => 1, :deal_id => d.id)
    assert o.save
    assert_equal d.coupon_count, 0
    # update order with 1 quantity, created state - no change
    o.quantity = 1
    o.amount = '10'
    assert o.save
    assert_equal d.confirmed_coupon_count, 0
    # update order as authorized - +1
    o.state = Order::AUTHORIZED
    assert o.save
    assert_equal d.coupon_count, 1
    # update order as paid - no change
    o.state = Order::PAID
    assert o.save
    assert_equal d.coupon_count, 1
    # order with different deal_id with no quantity - no change
    o = Order.new(:user_id => 1, :deal_id => d.id+1)
    assert o.save
    assert_equal d.confirmed_coupon_count, 1
    # order with different deal_id with 1 quantity - no change
    o.quantity = 1
    o.amount = '10'
    assert o.save
    assert_equal d.confirmed_coupon_count, 1
    # order with different deal_id as authorized - no change  
    o.state = Order::AUTHORIZED
    assert o.save
    assert_equal d.confirmed_coupon_count, 1      
    # order with new user_id with 2 quantity and authorized - +2 count
    o = Order.new(:user_id => 2, :deal_id => d.id, :quantity => 2, :amount => '20', :state => Order::AUTHORIZED)
    assert o.save
    assert_equal d.confirmed_coupon_count, 3
    # order with new user_id with 2 quantity and paid - +2 count
    o = Order.new(:user_id => 2, :deal_id => d.id, :quantity => 2, :amount => '20', :state => Order::PAID)
    assert o.save
    assert_equal d.confirmed_coupon_count, 5
  end
  
  def test_publish
    # publish with no deal codes - fails
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal d.max, 0
    assert !d.published
    assert !d.publish
    # publish with no images - fails
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    d = Deal.find_by_id(d.id)
    assert_equal d.deal_codes.size, 1
    assert_equal d.max, 0
    assert !d.published
    assert !d.publish
    # add one image - passes w/ max set to 1
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    assert_equal d.deal_images.size, 1
    assert d.publish
    assert d.published
    assert_equal d.max, 1
    # publish again? no changes?
    assert d.publish
    assert d.published
    assert_equal d.max, 1
  end
    
  def test_publish_max
    # publish with 1 deal code - max changes to 1
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :max => 2)
    assert d.save
    assert !d.published
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    assert_equal d.max, 1
    # publish again? no changes?
    assert d.publish
    assert_equal d.max, 1
    # publish with 3 deal codes - max stays at 2
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :max => 2)
    assert d.save
    assert !d.published
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf124')
    assert dc.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf125')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    assert_equal d.max, 2
  end
  
  def test_publish_incentive
    # create basic deal
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # add a deal incentive
    di = DealIncentive.new(:deal_id => d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '30.00', :number_required => 5)
    assert di.save
    d = Deal.find_by_id(d.id)
    assert !d.publish
    assert !d.published
    di = d.deal_incentive    
    assert_equal di.max, 0
    # add incentive code - ok
    dic = DealCode.new(:deal_id => d.id, :code => 'asdf123', :incentive => true)
    assert dic.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    assert d.published
    di = d.deal_incentive
    assert_equal di.max, 1
    # reset and lower incentive value - fail
    d.update_attributes(:published=>false)
    di.update_attributes(:incentive_value => '15.00')
    assert !d.publish
    assert !d.published
    di = d.deal_incentive
    assert_equal di.max, 1
    # raise incentive value back - ok
    di.update_attributes(:incentive_value => '20.00')
    assert d.publish
    assert d.published
    di = d.deal_incentive
    assert_equal di.max, 1        
    # publish again? no changes?
    assert d.publish
    assert d.published
    di = d.deal_incentive
    assert_equal di.max, 1
  end
  
  def test_publish_incentive_max
    # create basic deal
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # Add deal incentive with max = 2
    di = DealIncentive.new(:deal_id => d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '30.00', :number_required => 5, :max => 2)
    assert di.save
    # Add one deal incentive code
    dic = DealCode.new(:deal_id => d.id, :code => 'asdf123', :incentive => true)
    assert dic.save  
    d = Deal.find_by_id(d.id)
    assert d.publish
    di = d.deal_incentive
    assert_equal di.max, 1
    # publish again? no changes?
    assert d.publish
    di = d.deal_incentive
    assert_equal di.max, 1
    # publish with 3 deal incentive codes - max stays at 2
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    di = DealImage.new(:deal_id => d.id, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # Add deal incentive with max = 2
    di = DealIncentive.new(:deal_id => d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '30.00', :number_required => 5, :max => 2)
    assert di.save
    # Add 3 deal incentive codes
    dic = DealCode.new(:deal_id => d.id, :code => 'asdf123', :incentive => true)
    assert dic.save
    dic = DealCode.new(:deal_id => d.id, :code => 'asdf124', :incentive => true)
    assert dic.save
    dic = DealCode.new(:deal_id => d.id, :code => 'asdf125', :incentive => true)
    assert dic.save
    d = Deal.find_by_id(d.id)
    assert d.publish
    di = d.deal_incentive
    assert_equal di.max, 2
  end
  
  def test_delete
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    assert_equal d.active, true
    assert d.delete
    assert_equal d.active, false
  end
  
  def test_force_tip
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :min => 0)
    assert d.save
    # no orders - do nothing
    assert_equal d.confirmed_coupon_count, 0
    assert d.force_tip
    assert_equal d.min, 0
    # add an authorized order - still do nothing
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => Order::AUTHORIZED)
    assert o.save
    assert_equal d.confirmed_coupon_count, 1
    assert d.force_tip
    assert_equal d.min, 0
    # increase min to 1 - still do nothing
    assert d.update_attributes(:min => 1)
    assert_equal d.confirmed_coupon_count, 1
    assert d.force_tip
    assert_equal d.min, 1
    # increase min to 2 - sets to 1
    assert d.update_attributes(:min => 2)
    assert_equal d.confirmed_coupon_count, 1
    assert d.force_tip
    assert_equal d.min, 1
    # remove order - sets to 0
    assert o.update_attributes(:state => Order::CREATED)
    assert_equal d.confirmed_coupon_count, 0
    assert d.force_tip
    assert_equal d.min, 0
    # reset min to 1 and add a created order - still sets to 0
    assert d.update_attributes(:min => 1)
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20')
    assert o.save    
    assert_equal d.confirmed_coupon_count, 0
    assert d.force_tip
    assert_equal d.min, 0
  end
  
  def test_is_tipped
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :min => 1)
    assert d.save
    assert !d.is_tipped
    # unconfirmed order shouldn't tip deal
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20')
    assert o.save
    assert !d.is_tipped
    # add one authorized - tipped
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => Order::AUTHORIZED)
    assert o.save 
    assert d.is_tipped
    # make it paid - still tipped
    o.state = Order::PAID
    assert o.save
    assert d.is_tipped
    # add another authorized - still tipped
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => Order::AUTHORIZED)
    assert o.save 
    assert d.is_tipped
        
    assert !d.is_tipped(0)
    assert d.is_tipped(1)
    assert d.is_tipped(2)
  end
  
  def test_is_maxed
    Order.delete_all
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :max => 1)
    assert d.save
    assert !d.is_maxed
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20')
    assert o.save
    assert d.is_maxed
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20')
    assert o.save   
    assert d.is_maxed
    
    assert !d.is_maxed(0)
    assert d.is_maxed(1)
    assert d.is_maxed(2)
  end
  
  def test_is_started
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today.beginning_of_day, :end_date => today.end_of_day, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.is_started
    assert !d.is_started(yesterday.end_of_day)
    assert d.is_started(tomorrow.beginning_of_day)
    
    # start_date yesterday - true
    d.start_date = yesterday.beginning_of_day
    assert d.is_started
    
    # start_date tomorrow - false
    d.start_date = tomorrow.beginning_of_day
    assert !d.is_started
  end
  
  def test_is_started_timezone
    # merchant's time zone
    Time.zone = 'US/Pacific'
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => Time.zone.now, :end_date => Time.zone.now + 10.minutes, 
      :expiration_date => Time.zone.now + 10.minutes, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    # User w/ same time zone - pass
    assert d.is_started
    assert !d.is_started(Time.zone.now - 1.hours)
    assert d.is_started(Time.zone.now + 1.hours)    
    # User w/ earlier time zone - shouldn't change
    Time.zone = 'US/Eastern'
    assert d.is_started
    assert !d.is_started(Time.zone.now - 1.hours)
    assert d.is_started(Time.zone.now + 1.hours)    
    # User w/ later time zone - shouldn't change
    Time.zone = 'US/Hawaii'
    assert d.is_started
    assert !d.is_started(Time.zone.now - 1.hours)
    assert d.is_started(Time.zone.now + 1.hours)
    # return back to UTC
    Time.zone = 'Etc/UTC'
  end
  
  def test_is_ended
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today.beginning_of_day, :end_date => today.end_of_day, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.is_ended
    assert !d.is_ended(yesterday.end_of_day)
    assert d.is_ended(tomorrow.beginning_of_day)
    
    # end_date yesterday - true
    d.end_date = yesterday.end_of_day
    assert d.is_ended
    
    # end_date tomorrow - false
    d.end_date = tomorrow.end_of_day
    assert !d.is_ended
  end
  
  def test_is_ended_timezone
    # merchant's time zone
    Time.zone = 'US/Pacific'
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => Time.zone.now - 10.minutes, :end_date => Time.zone.now, 
      :expiration_date => Time.zone.now, :deal_price => '10.00', :deal_value => '20.00')
    # User w/ same time zone - pass
    assert d.is_ended
    assert !d.is_ended(Time.zone.now - 1.hours)
    assert d.is_ended(Time.zone.now + 1.hours)    
    # User w/ earlier time zone - shouldn't change
    Time.zone = 'US/Eastern'
    assert d.is_ended
    assert !d.is_ended(Time.zone.now - 1.hours)
    assert d.is_ended(Time.zone.now + 1.hours)    
    # User w/ later time zone - shouldn't change
    Time.zone = 'US/Hawaii'
    assert d.is_ended
    assert !d.is_ended(Time.zone.now - 1.hours)
    assert d.is_ended(Time.zone.now + 1.hours)
    # return back to UTC
    Time.zone = 'Etc/UTC'
  end
  
  def test_is_expired
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today.beginning_of_day, :end_date => today.end_of_day, 
      :expiration_date => today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.is_expired
    assert !d.is_expired(yesterday.end_of_day)
    assert d.is_expired(tomorrow.beginning_of_day)
    
    # expiration_date yesterday - true
    d.expiration_date = yesterday.end_of_day
    assert d.is_expired
    
    # expiration_date tomorrow - false
    d.expiration_date = tomorrow.end_of_day
    assert !d.is_expired   
  end
  
  def test_is_expired_timezone
    # merchant's time zone
    Time.zone = 'US/Pacific'
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => Time.zone.now - 10.minutes, :end_date => Time.zone.now, 
      :expiration_date => Time.zone.now, :deal_price => '10.00', :deal_value => '20.00')
    # User w/ same time zone - pass
    assert d.is_expired
    assert !d.is_expired(Time.zone.now - 1.hours)
    assert d.is_expired(Time.zone.now + 1.hours)    
    # User w/ earlier time zone - shouldn't change
    Time.zone = 'US/Eastern'
    assert d.is_expired
    assert !d.is_expired(Time.zone.now - 1.hours)
    assert d.is_expired(Time.zone.now + 1.hours)    
    # User w/ later time zone - shouldn't change
    Time.zone = 'US/Hawaii'
    assert d.is_expired
    assert !d.is_expired(Time.zone.now - 1.hours)
    assert d.is_expired(Time.zone.now + 1.hours)
    # return back to UTC
    Time.zone = 'Etc/UTC'
  end
  
  def test_time_difference_for_display
    seconds = 0
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 0, :minutes => 0, :seconds => 0}
    seconds = seconds + 5  
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 0, :minutes => 0, :seconds => 5}
    seconds = seconds + 60    
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 0, :minutes => 1, :seconds => 5}
    seconds = seconds + 60*2 
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 0, :minutes => 3, :seconds => 5}
    seconds = seconds + 3600*2     
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 2, :minutes => 3, :seconds => 5}
    seconds = seconds + 86400*1     
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 1, :hours => 2, :minutes => 3, :seconds => 5}
    seconds = seconds + 86400*10     
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 11, :hours => 2, :minutes => 3, :seconds => 5}
    
    seconds *= -1
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => -11, :hours => -2, :minutes => -3, :seconds => -5}
    seconds = -10
    difference = Deal.time_difference_for_display(seconds)
    assert_equal difference, {:days => 0, :hours => 0, :minutes => 0, :seconds => -10}                 
  end
  
  def test_time_left
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today.beginning_of_day, :end_date => today.end_of_day, 
      :expiration_date => today.end_of_day, :deal_price => '10.00', :deal_value => '20.00')
    difference = d.time_left
    assert difference < 86400
 
    # end_date yesterday
    d.end_date = yesterday.end_of_day
    difference = d.time_left
    assert difference < 0
    assert difference > -86400
    
    # end_date tomorrow
    d.end_date = tomorrow.end_of_day
    difference = d.time_left
    assert difference > 86400
  end
  
  def test_time_left_timezone
    # merchant's time zone
    Time.zone = 'US/Pacific'
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => Time.zone.now, :end_date => Time.zone.now + 10.minutes, 
      :expiration_date => Time.zone.now + 10.minutes, :deal_price => '10.00', :deal_value => '20.00')
    # User w/ same time zone - pass
    difference = d.time_left
    assert difference > 60*9
    assert difference <= 60*10
    # User w/ earlier time zone - shouldn't change
    Time.zone = 'US/Eastern'
    difference = d.time_left
    assert difference > 60*9
    assert difference <= 60*10 
    # User w/ later time zone - shouldn't change
    Time.zone = 'US/Hawaii'
    difference = d.time_left
    assert difference > 60*9
    assert difference <= 60*10
    # return back to UTC
    Time.zone = 'Etc/UTC'
  end
  
  def test_views_in_date_range
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save 
    # non-deal user_action
    ua = UserAction.new(:controller => 'user', :action => 'home', :method => 'get')
    assert ua.save
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 0
    # deal user_action, other controller
    ua = UserAction.new(:controller => 'merchant', :action => 'deal', :deal_id => d.id, :method => 'get')
    assert ua.save   
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 0
    # deal user_action, other deal
    ua = UserAction.new(:controller => 'user', :action => 'deal', :deal_id => d.id + 1, :method => 'get')  
    assert ua.save
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 0
    # deal user_action
    ua = UserAction.new(:controller => 'user', :action => 'deal', :deal_id => d.id, :method => 'get') 
    assert ua.save
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1
    
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day + 1.days), 1
    assert_equal d.views_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day), 1
    assert_equal d.views_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day - 1.days), 0
    assert_equal d.views_in_date_range(Time.zone.today + 1.days, Time.zone.today.end_of_day + 1.days), 0
    
    # add another
    ua = UserAction.new(:controller => 'user', :action => 'deal', :deal_id => d.id, :method => 'get') 
    assert ua.save
    assert_equal d.views_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 2    
  end
  
  def test_orders_in_date_range
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    # created order
    o = Order.new(:user_id => 1000, :deal_id => d.id, :quantity => 1, :amount => '10.00')
    assert o.save
    assert_equal d.orders_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 0
    # authorize
    o.update_attributes(:state => Order::AUTHORIZED, :authorized_at => Time.zone.now)
    assert_equal d.orders_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1
    # authorized order for another deal - no change
    o = Order.new(:user_id => 1000, :deal_id => d.id + 1, :quantity => 1, :amount => '10.00', 
      :state => Order::AUTHORIZED, :authorized_at => Time.zone.now)
    assert o.save
    assert_equal d.orders_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1

    assert_equal d.orders_in_date_range(Time.zone.today, Time.zone.today.end_of_day + 1.days), 1
    assert_equal d.orders_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day), 1
    assert_equal d.orders_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day - 1.days), 0
    assert_equal d.orders_in_date_range(Time.zone.today + 1.days, Time.zone.today.end_of_day + 1.days), 0
    
    # add another
    o = Order.new(:user_id => 1000, :deal_id => d.id, :quantity => 1, :amount => '10.00', 
      :state => Order::AUTHORIZED, :authorized_at => Time.zone.now)
    assert o.save
    assert_equal d.orders_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 2    
  end
  
  def test_coupons_in_date_range
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    o = Order.new(:user_id => 1000, :deal_id => d.id, :quantity => 1, :amount => '10.00', 
      :state => Order::AUTHORIZED, :authorized_at => Time.zone.now)
    assert o.save
    # Pending coupon
    c = Coupon.new(:user_id => 1000, :deal_id => d.id, :order_id => o.id, :deal_code_id => 100)
    assert c.save
    assert_equal c.state, 'Pending'
    assert_equal d.coupons_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1
    # Paid coupon - still counts
    o.update_attributes(:state => Order::PAID)
    c = Coupon.find_by_id(c.id)
    assert_equal c.state, 'Active'
    assert_equal d.coupons_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1    
    # Coupon for another deal - no change
    c = Coupon.new(:user_id => 1000, :deal_id => d.id + 1, :order_id => 1, :deal_code_id => 101)
    assert c.save    

    assert_equal d.coupons_in_date_range(Time.zone.today, Time.zone.today.end_of_day + 1.days), 1
    assert_equal d.coupons_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day), 1
    assert_equal d.coupons_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day - 1.days), 0
    assert_equal d.coupons_in_date_range(Time.zone.today + 1.days, Time.zone.today.end_of_day + 1.days), 0
    
    # add another
    c = Coupon.new(:user_id => 1000, :deal_id => d.id, :order_id => o.id, :deal_code_id => 102)
    assert c.save
    assert_equal d.coupons_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 2
  end
  
  def test_shares_in_date_range
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert d.save
    # Share (not posted) - doesn't count
    s = Share.new(:user_id => 1000, :deal_id => d.id, :facebook_id => 100000)
    assert s.save
    assert_equal d.shares_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 0
    # Post - counts
    s.update_attributes(:post_id => 1234, :posted => true)
    assert_equal d.shares_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 1    
    # Share for another deal - no change
    s = Share.new(:user_id => 1000, :deal_id => d.id + 1, :facebook_id => 100000, :post_id => 1234, :posted => true)
    assert s.save
    
    assert_equal d.shares_in_date_range(Time.zone.today, Time.zone.today.end_of_day + 1.days), 1
    assert_equal d.shares_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day), 1
    assert_equal d.shares_in_date_range(Time.zone.today - 1.days, Time.zone.today.end_of_day - 1.days), 0
    assert_equal d.shares_in_date_range(Time.zone.today + 1.days, Time.zone.today.end_of_day + 1.days), 0
    
    # Add another posted share
    s = Share.new(:user_id => 1000, :deal_id => d.id, :facebook_id => 100000, :post_id => 1234, :posted => true)
    assert s.save
    assert_equal d.shares_in_date_range(Time.zone.today, Time.zone.today.end_of_day), 2      
  end
  
end