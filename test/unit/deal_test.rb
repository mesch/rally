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
    # check money fields
    assert_equal d.deal_price, 10.00
    assert_equal d.deal_value, 20.00
    assert d.save
    # check id is protected
    d.id = 1
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
  
end
