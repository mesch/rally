class UserAction < ActiveRecord::Base
  validates_presence_of :controller, :action, :method
  
  belongs_to :visitor
  belongs_to :user
  belongs_to :merchant
  belongs_to :deal
  
  attr_protected :id
  
end
