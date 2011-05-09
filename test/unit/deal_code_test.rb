require 'test_helper'

class DealCodeTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deal_images

  def setup
    DealCode.delete_all
  end
  
  def test_deal_code_basic
    di = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert_not_nil di.deal_id
    assert_not_nil di.code
    assert di.save
    # check id is protected
    di.id = 1
    assert !di.save
  end
  
  def test_deal_image_missing_fields
    di = DealCode.new(:deal_id => nil, :code => 'asdf123')  
    assert !di.save
    di = DealCode.new(:deal_id => 1, :code => nil) 
    assert !di.save
  end
  
  def test_deal_image_multiple
    di = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert di.save
    # same deal, new code - ok
    di = DealCode.new(:deal_id => 1, :code => 'asdf124')
    assert di.save
    # new deal, same code - ok
    di = DealCode.new(:deal_id => 2, :code => 'asdf123')
    assert di.save
    # same deal, same code - fail
    di = DealCode.new(:deal_id => 1, :code => 'asdf123')
    assert !di.save        
  end

end
