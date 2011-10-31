require 'test_helper'

class DealIncentiveTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deals
  
  def setup
    DealIncentive.delete_all
    @d = @burger_deal
  end

  def test_create_basic
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    # check defaults
    assert_equal di.max, 0
    # check money fields
    assert_equal di.incentive_price, 10.00
    assert_equal di.incentive_value, 20.00
    assert di.save
    # check id is protected
    old_id = di.id
    di.id = old_id+1
    di.deal_id = di.deal_id + 1
    assert di.save
    di = DealIncentive.find(old_id)
    assert di
    assert_equal di.id, old_id
  end
  
  def test_ranges
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    di.max = -1
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    di.number_required = -1
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    di.number_required = 0
    assert !di.save
  end
  
  def test_metric_type
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert di.save
    di = DealIncentive.new(:deal_id => @d.id + 1, :metric_type => DealIncentive::PURCHASE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert di.save
    di = DealIncentive.new(:deal_id => @d.id + 2, :metric_type => 'SOMETHING_ELSE', 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert !di.save
  end


  def test_missing_fields
    di = DealIncentive.new(:deal_id => nil, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => nil, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => nil, :incentive_value => '20.00', :number_required => 5)
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => nil, :number_required => 5)
    assert !di.save
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => nil)
    assert !di.save
  end
  
  def test_create_full
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5, :max => 1000)
    assert di.save
    # check defaults
    assert_not_equal di.max, 0
  end
  
  def test_create_multiple
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5, :max => 1000)
    assert di.save
    # Same deal - fails
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5, :max => 1000)
    assert !di.save
    # Different deal - ok
    di = DealIncentive.new(:deal_id => @d.id + 1, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5, :max => 1000)
    assert di.save    
  end
  
  def test_added_value
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert di.save
    assert_equal di.added_value, 0.to_money
    DealIncentive.delete_all
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '30.00', :number_required => 5)
    assert di.save
    assert_equal di.added_value, 10.to_money
  end
  
  def test_reserved_coupons_count
    # delete all current deal incentive codes
    DealCode.delete_all(["deal_id = ? AND incentive = ?", @d.id, true])
    
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 5)
    assert di.save
    assert_equal di.reserved_coupons_count, 0
    # Create an unreserved non-incentive code - no change
    dc = DealCode.new(:deal_id => @d.id, :code => "1234")
    assert dc.save
    assert_equal di.reserved_coupons_count, 0
    # reserve it - no change
    dc.update_attributes!(:reserved => true)
    assert_equal di.reserved_coupons_count, 0
    # Create an unreserved incentive code for a different deal - no change
    dc = DealCode.new(:deal_id => @d.id + 1, :code => "1234")
    assert dc.save
    assert_equal di.reserved_coupons_count, 0
    # reserve it - no change
    dc.update_attributes!(:reserved => true)
    assert_equal di.reserved_coupons_count, 0
    # Create an unreserved incentive code - no change
    dc = DealCode.new(:deal_id => @d.id, :code => "1234", :incentive => true)
    assert dc.save
    assert_equal di.reserved_coupons_count, 0
    # reserve it - add 1
    dc.update_attributes!(:reserved => true)
    assert_equal di.reserved_coupons_count, 1
    # Create another unreserved incentive code - no change
    dc = DealCode.new(:deal_id => @d.id, :code => "1235", :incentive => true)
    assert dc.save
    assert_equal di.reserved_coupons_count, 1
    # reserve it - add 1
    dc.update_attributes!(:reserved => true)
    assert_equal di.reserved_coupons_count, 2
  end
  
  def test_is_accomplished
    u = @test_user
    Share.delete_all
    di = DealIncentive.new(:deal_id => @d.id, :metric_type => DealIncentive::SHARE, 
      :incentive_price => '10.00', :incentive_value => '20.00', :number_required => 1)
    assert di.save
    # no shares - fails
    assert !di.is_accomplished(u.id)
    # add one share - passes
    share = Share.new(:user_id => u.id, :deal_id => @d.id, :facebook_id => 1000)
    assert share.save
    assert di.is_accomplished(u.id)
    # increase number_required - fails
    di.update_attributes!(:number_required => 2)
    assert !di.is_accomplished(u.id)    
    # add share to same person - still fails
    share = Share.new(:user_id => u.id, :deal_id => @d.id, :facebook_id => 1000)
    assert share.save
    assert !di.is_accomplished(u.id)
    # add share to a different deal - still fails
    share = Share.new(:user_id => u.id, :deal_id => @d.id+1, :facebook_id => 1000)
    assert share.save
    assert !di.is_accomplished(u.id)    
    # add share from a different user - still fails
    share = Share.new(:user_id => u.id+1, :deal_id => @d.id, :facebook_id => 1000)
    assert share.save
    assert !di.is_accomplished(u.id)
    # add share to new facebook_id - passes
    share = Share.new(:user_id => u.id, :deal_id => @d.id, :facebook_id => 1001)
    assert share.save
    assert di.is_accomplished(u.id)    
  end

end
