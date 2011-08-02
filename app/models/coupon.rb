class Coupon < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :order_id

  # todo: a way to make :deal_code_id unique, even though field is nullable?
  
  attr_protected :id
  
  belongs_to :deal
  belongs_to :user
  belongs_to :order
  belongs_to :deal_code

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :order => 'created_at desc'
  end

  def state
    if self.deal.is_expired
      return 'Expired'
    elsif self.order.state == Order::PAID
      return 'Active'
    else
      return 'Pending'
    end
  end  
  
end
