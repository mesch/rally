class DealIncentiveCode < ActiveRecord::Base
  validates_presence_of :deal_incentive_id, :code
  validates_length_of :code, :maximum => 40
  validates_uniqueness_of :code, :scope => :deal_incentive_id
  
  attr_protected :id
  
  belongs_to :deal_incentive
  
end
