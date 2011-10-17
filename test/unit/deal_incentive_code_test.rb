require 'test_helper'

class DealIncentiveCodeTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deal_incentive_codes

  def setup
    DealIncentiveCode.delete_all
  end
  
  def test_deal_incentive_code_create_basic
    dic = DealIncentiveCode.new(:deal_incentive_id => 1, :code => 'asdf123')
    assert_not_nil dic.deal_incentive_id
    assert_not_nil dic.code
    assert dic.save
    # check id is protected
    old_id = dic.id
    dic.id = old_id+1
    assert !dic.save
  end
  
  def test_deal_incentive_code_missing_fields
    dic = DealIncentiveCode.new(:deal_incentive_id => nil, :code => 'asdf123')  
    assert !dic.save
    dic = DealIncentiveCode.new(:deal_incentive_id => 1, :code => nil) 
    assert !dic.save
  end
  
  def test_deal_incentive_code_create_multiple
    dic = DealIncentiveCode.new(:deal_incentive_id => 1, :code => 'asdf123')
    assert dic.save
    # same deal, new code - ok
    dic = DealIncentiveCode.new(:deal_incentive_id => 1, :code => 'asdf124')
    assert dic.save
    # new deal, same code - ok
    dic = DealIncentiveCode.new(:deal_incentive_id => 2, :code => 'asdf123')
    assert dic.save
    # same deal, same code - fail
    dic = DealIncentiveCode.new(:deal_incentive_id => 1, :code => 'asdf123')
    assert !dic.save       
  end
end
