class Coupon < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :order_id

  # todo: a way to make :deal_code_id unique, even though field is nullable?
  
  belongs_to :deal
  belongs_to :user
  belongs_to :order
  belongs_to :deal_code

  def state
    if self.deal.is_expired
      return 'Expired'
    elsif self.order.state == OPTIONS[:order_states][:paid]
      return 'Active'
    else
      return 'Pending'
    end
  end  
  
end
