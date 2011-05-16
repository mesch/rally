require 'test_helper'

class DealCodeTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deal_codes

  def setup
    DealCode.delete_all
  end
  
  def test_deal_code_create_basic
    dc = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert_not_nil dc.deal_id
    assert_not_nil dc.code
    assert dc.save
    # check id is protected
    old_id = dc.id
    dc.id = old_id+1
    assert !dc.save
  end
  
  def test_deal_code_missing_fields
    dc = DealCode.new(:deal_id => nil, :code => 'asdf123')  
    assert !dc.save
    dc = DealCode.new(:deal_id => 1, :code => nil) 
    assert !dc.save
  end
  
  def test_deal_code_create_multiple
    dc = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert dc.save
    # same deal, new code - ok
    dc = DealCode.new(:deal_id => 1, :code => 'asdf124')
    assert dc.save
    # new deal, same code - ok
    dc = DealCode.new(:deal_id => 2, :code => 'asdf123')
    assert dc.save
    # same deal, same code - fail
    dc = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert !dc.save        
  end

end
