class DealCode < ActiveRecord::Base
  validates_presence_of :deal_id, :code
  
  validates_uniqueness_of :code, :scope => :deal_id
  
  belongs_to :deal

end
