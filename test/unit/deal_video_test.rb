require 'test_helper'

class DealVideoTest < ActiveSupport::TestCase
  self.use_instantiated_fixtures  = true
  fixtures :deal_images

  def setup
    DealVideo.delete_all
  end
  
  def test_deal_video_basic
    dv = DealVideo.new(:deal_id => 1, :counter => 1,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)  
    assert dv.active
    assert_not_nil dv.deal_id
    assert_not_nil dv.counter
    assert dv.save
    # check id is protected
    dv.id = dv.id + 1
    assert !dv.save
  end
  
  def test_deal_video_missing_fields
    dv = DealVideo.new(:deal_id => nil, :counter => 1,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)    
    assert !dv.save
    dv = DealVideo.new(:deal_id => 1, :counter => nil,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)    
    assert !dv.save
  end
  
  def test_deal_video_multiple
    dv = DealVideo.new(:deal_id => 1, :counter => 1,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)
    assert dv.save
    # same deal, new counter - ok
    dv = DealVideo.new(:deal_id => 1, :counter => 2,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)
    assert dv.save
    # new deal, same counter - ok
    dv = DealVideo.new(:deal_id => 2, :counter => 1,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)
    assert dv.save
    # same deal, same counter - fail
    dv = DealVideo.new(:deal_id => 1, :counter => 1,
      :video_file_name => 'test.flv', :video_content_type => 'video/x-flv', :video_file_size => 1000000)
    assert !dv.save        
  end  
  
end

