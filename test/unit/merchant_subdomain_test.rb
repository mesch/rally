require 'test_helper'

class MerchantSubdomainTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :coupons

  def setup
    MerchantSubdomain.delete_all
  end
  
  def test_subdomain_create_basic
    sd = MerchantSubdomain.new(:merchant_id => 1000, :subdomain => 'testing')
    assert sd.save
  end
  
  def test_subdomain_create_multiple
    sd = MerchantSubdomain.new(:merchant_id => 1000, :subdomain => 'testing')
    assert sd.save
    # same merchant_id - ok (for now, ideally merchant_id (except for nulls would be unique)
    sd = MerchantSubdomain.new(:merchant_id => 1000, :subdomain => 'testingtesting')
    assert sd.save
    # same subdomain and same merchant_id - fail 
    sd = MerchantSubdomain.new(:merchant_id => 1000, :subdomain => 'testing')
    assert !sd.save
    # same subdomain and new merchant_id - fail     
    sd = MerchantSubdomain.new(:merchant_id => 1001, :subdomain => 'testing')
    assert !sd.save       
  end
  
  def test_create_subdomain_system
    # can create multiple system domains with merchant_id = nil
    sd = MerchantSubdomain.new(:merchant_id => nil, :subdomain => 'testing')
    assert sd.save
    sd = MerchantSubdomain.new(:merchant_id => nil, :subdomain => 'testingtesting')
    assert sd.save
  end
  
  def test_subdomain_missing_fields
    #ok
    sd = MerchantSubdomain.new(:merchant_id => nil, :subdomain => 'testing')
    assert sd.save
    #fail
    sd = MerchantSubdomain.new(:merchant_id => 1000, :subdomain => nil)
    assert !sd.save
  end
  
  def test_subdomain_empty_subdomain
    #fail
    sd = MerchantSubdomain.new(:merchant_id => nil, :subdomain => '')
    assert !sd.save
  end
  
  def test_get_logo
    m = @bob
    sd = @bob_subdomain
    assert_equal sd.get_logo, m.get_logo
    assert_equal sd.get_logo_footer, m.get_logo_footer
    sd = @www_subdomain
    assert_nil sd.get_logo
    assert_nil sd.get_logo_footer
  end
  
end
