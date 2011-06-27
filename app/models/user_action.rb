class UserAction < ActiveRecord::Base
  validates_presence_of :controller, :action, :method
  
  belongs_to :visitor
  belongs_to :user
  belongs_to :merchant
  belongs_to :deal
  
  attr_protected :id
  
  def self.log(options={})
    ua = UserAction.new(:controller => options[:controller], :action => options[:action], :method => options[:method],
        :visitor_id => options[:visitor_id], :user_id => options[:user_id], :merchant_id => options[:merchant_id], 
        :deal_id => options[:deal_id])
    unless ua.save
      logger.error "log_user_action: Couldn't log User Action: #{ua}"
    end
  end
  
end
