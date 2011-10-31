require 'test_helper'

class ShareTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures = true
  fixtures :shares

  def setup
    Share.delete_all
  end
  
  def test_share_create_basic
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => 100000)
    assert_nil s.post_id
    assert_equal s.posted, false
    assert s.save  
    # check id is protected
    old_id = s.id
    s.id = old_id+1
    assert s.save
    s = Share.find(old_id)
    assert_equal s.id, old_id
  end
  
  def test_share_create_multiple
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => 100000)
    assert s.save
    # same user_id, same deal_id, same facebook_id - ok
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => 100000)
    assert s.save  
  end
  
  def test_share_missing_fields
    s = Share.new(:user_id => nil, :deal_id => 1, :facebook_id => 100000, :post_id => 1234, :posted => true)
    assert !s.save
    s = Share.new(:user_id => 1000, :deal_id => nil, :facebook_id => 100000, :post_id => 1234, :posted => true)
    assert !s.save
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => nil, :post_id => 1234, :posted => true)
    assert !s.save
    # missing post_id or posted - ok
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => 100000, :post_id => nil, :posted => true)
    assert s.save
    s = Share.new(:user_id => 1000, :deal_id => 1, :facebook_id => 100000, :post_id => 1234, :posted => nil)
    assert s.save
  end
end