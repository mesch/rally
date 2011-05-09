require 'test_helper'

class DealImageTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deal_images

  def setup
    DealImage.delete_all
  end
  
  def test_deal_image_basic
    di = DealImage.new(:deal_id => 1, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)  
    assert di.active
    assert_not_nil di.deal_id
    assert_not_nil di.counter
    assert di.save
    # check id is protected
    di.id = 1
    assert !di.save
  end
  
  def test_deal_image_missing_fields
    di = DealImage.new(:deal_id => nil, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)    
    assert !di.save
    di = DealImage.new(:deal_id => 1, :counter => nil,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)    
    assert !di.save
  end
  
  def test_deal_image_multiple
    di = DealImage.new(:deal_id => 1, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # same deal, new counter - ok
    di = DealImage.new(:deal_id => 1, :counter => 2,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # new deal, same counter - ok
    di = DealImage.new(:deal_id => 2, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert di.save
    # same deal, same counter - fail
    di = DealImage.new(:deal_id => 1, :counter => 1,
      :image_file_name => 'test.png', :image_content_type => 'image/png', :image_file_size => 1000)
    assert !di.save        
  end  
  
end
