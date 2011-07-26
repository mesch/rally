class DealImage < ActiveRecord::Base
  MAX_IMAGE_SIZE = 1048576 # Max bytes (1 MB)
  CONTENT_TYPES = ['image/jpg', 'image/jpeg', 'image/pjpeg', 'image/gif', 'image/png', 'image/x-png', 'image/bmp']
  THUMB_SIZE = "100x100!"
  DISPLAY_SIZE = "440x275!"

  validates_attachment_presence :image
  validates_attachment_size :image, :less_than => MAX_IMAGE_SIZE
  validates_attachment_content_type :image, { :content_type => CONTENT_TYPES }

  validates_presence_of :deal_id, :counter
  validates_uniqueness_of :counter, :scope => :deal_id

  attr_protected :id

  belongs_to :deal

  has_attached_file :image, {
    :styles => { 
      :thumb => THUMB_SIZE,
      :display => DISPLAY_SIZE
    },
    :default_url => OPTIONS[:deal_image_default_url]
  }.merge(OPTIONS[:paperclip_storage_options])
  
end
