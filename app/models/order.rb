class Order < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :quantity, :amount
  
  money :amount, :currency => false
  
  belongs_to :deal
  belongs_to :user
  
  # try to reserve the quantity of coupons
  def reserve_quantity(quantity)
    quantity = quantity.to_i
    begin
      Deal.transaction do
        deal = Deal.find(self.deal.id, :lock => true)
        
        if deal.coupon_count + quantity - self.quantity <= deal.max
          self.update_attributes!(:quantity => quantity, :amount => quantity*deal.deal_price.to_f, :updated_at => Time.zone.now)
          return true
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      # do anything here?
    end
    return false
  end
  
  # create coupons - after payment confirmation
  def create_coupons()
    begin
      Order.transaction do
        deal = Deal.find(self.deal.id)
        if deal.deal_codes.size == 0
          for i in (1..self.quantity)
            Coupon.create!(:user_id => self.user.id, :deal_id => deal.id, :order_id => self.id)
          end        
        else
          for i in (1..self.quantity)
            dc = DealCode.find(:first, :conditions => ["deal_id = ? AND reserved = ?", deal.id, false], :lock => true)
            if dc
              Coupon.create!(:user_id => self.user.id, :deal_id => deal.id, :order_id => self.id, :deal_code_id => dc.id)
              dc.update_attributes!(:reserved => true)
            end
          end
        end
      end
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      # do anything here?
    end
    return false
  end
  
  def is_timed_out(timeout=nil)
    unless timeout
      timeout = OPTIONS[:order_timeout]
    end
    
    updated_at = self.updated_at
    # force update for next checks
    self.update_attributes(:updated_at => Time.zone.now)
    
    # check updated_at
    if updated_at + timeout.seconds < Time.zone.now
      return true
    end
    return false
  end

end
