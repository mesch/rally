class DealCode < ActiveRecord::Base

  validates_presence_of :deal_id, :code
  
  belongs_to :deal

end
