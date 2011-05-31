require 'test_helper'

class DealTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deals
  
  def setup
    @m = Deal.find(:first)
    @start = Time.zone.today
    @end = Time.zone.today + 1.days
    @expiration = Time.zone.today + 1.months
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
    d.video = 'http://www.mediacollege.com/video-gallery/testclips/barsandtone.flv'
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
    # title - 50 chars
    string = ""
    length = 51
    length.times{ string << "a"}
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.title = string
    assert !d.save
    # description - 200 chars
    string = ""
    length = 201
    length.times{ string << "a"}
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    d.description = string
    assert !d.save
    # terms - 200 chars
    string = ""
    length = 201
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
    o.state = OPTIONS[:order_states][:authorized]
    assert o.save
    assert_equal d.coupon_count, 1
    # update order as paid - no change
    o.state = OPTIONS[:order_states][:paid]
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
    o.state = OPTIONS[:order_states][:authorized]
    assert o.save
    assert_equal d.coupon_count, 1
    # update order as paid - no change
    o.state = OPTIONS[:order_states][:paid]
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
    o.state = OPTIONS[:order_states][:authorized]
    assert o.save
    assert_equal d.confirmed_coupon_count, 1      
    # order with new user_id with 2 quantity and authorized - +2 count
    o = Order.new(:user_id => 2, :deal_id => d.id, :quantity => 2, :amount => '20', :state => OPTIONS[:order_states][:authorized])
    assert o.save
    assert_equal d.confirmed_coupon_count, 3
    # order with new user_id with 2 quantity and paid - +2 count
    o = Order.new(:user_id => 2, :deal_id => d.id, :quantity => 2, :amount => '20', :state => OPTIONS[:order_states][:paid])
    assert o.save
    assert_equal d.confirmed_coupon_count, 5
  end
  
  def test_publish
    # publish with no deal codes - max doesn't change
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :max => 2)
    assert d.save
    assert !d.published
    assert d.publish
    assert_equal d.max, 2
    # publish again? no changes?
    assert d.publish
    assert_equal d.max, 2
    # publish with 1 deal code - max changes to 1
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => @start, :end_date => @end, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00', :max => 2)
    assert d.save
    assert !d.published
    dc = DealCode.new(:deal_id => d.id, :code => 'asdf123')
    assert dc.save
    assert d.publish
    assert_equal d.max, 1
    # publish again? no changes?
    assert d.publish
    assert_equal d.max, 1
    # publish with 3 deal codes - max changes to 3
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
    assert d.publish
    assert_equal d.max, 3
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
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => OPTIONS[:order_states][:authorized])
    assert o.save 
    assert d.is_tipped
    # make it paid - still tipped
    o.state = OPTIONS[:order_states][:paid]
    assert o.save
    assert d.is_tipped
    # add another authorized - still tipped
    o = Order.new(:user_id => 1, :deal_id => d.id, :quantity => 1, :amount => '20', :state => OPTIONS[:order_states][:authorized])
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
  
  def test_is_ended
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today, :end_date => today, 
      :expiration_date => @expiration, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.is_ended
    assert !d.is_ended(yesterday)
    assert d.is_ended(tomorrow)
    
    # end_date yesterday - true
    d.end_date = yesterday
    assert d.is_ended
    
    # end_date tomorrow - false
    d.end_date = tomorrow
    assert !d.is_ended
  end
  
  def test_is_expired
    today = Time.zone.today
    yesterday = Time.zone.today - 1.days
    tomorrow = Time.zone.today + 1.days
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today, :end_date => today, 
      :expiration_date => today, :deal_price => '10.00', :deal_value => '20.00')
    assert !d.is_expired
    assert !d.is_expired(yesterday)
    assert d.is_expired(tomorrow)
    
    # expiration_date yesterday - true
    d.expiration_date = yesterday
    assert d.is_expired
    
    # expiration_date tomorrow - false
    d.expiration_date = tomorrow
    assert !d.is_expired   
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
    d = Deal.new(:merchant_id => @m.id, :title => 'dealio', :start_date => today, :end_date => today, 
      :expiration_date => today, :deal_price => '10.00', :deal_value => '20.00')
    difference = d.time_left
    assert difference < 86400
 
    # end_date yesterday
    d.end_date = yesterday
    difference = d.time_left
    assert difference < 0
    assert difference > -86400
    
    # end_date tomorrow
    d.end_date = tomorrow
    difference = d.time_left
    assert difference > 86400
  end
  
end