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

end
