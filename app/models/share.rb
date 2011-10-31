class Share < ActiveRecord::Base

  validates_presence_of :user_id, :deal_id, :facebook_id
    
  attr_protected :id

  belongs_to :user
  belongs_to :deal

end
