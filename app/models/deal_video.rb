class DealVideo < ActiveRecord::Base
  MAX_VIDEO_SIZE = 20971520 # Max bytes (20 MB)
  CONTENT_TYPES = ['application/x-shockwave-flash', 'application/flv', 'video/x-flv', 'flv-application/octet-stream', 'application/octet-stream']

  validates_attachment_presence :video
  validates_attachment_size :video, :less_than => MAX_VIDEO_SIZE
  validates_attachment_content_type :video, { :content_type => CONTENT_TYPES }

  validates_presence_of :deal_id, :counter
  validates_uniqueness_of :counter, :scope => :deal_id

  attr_protected :id

  belongs_to :deal

  has_attached_file :video, {
    :default_url => OPTIONS[:deal_video_default_url]
  }.merge(OPTIONS[:paperclip_storage_options])
end
