class Order < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :quantity, :amount
  
  money :amount, :currency => false
  
  belongs_to :deal
  belongs_to :user

  def self.unconfirmed_order(user_id, deal_id)
    if order = Order.find(:first, :conditions => ["user_id = ? AND deal_id = ? AND confirmation_code IS NULL", user_id, deal_id])
      return order
    else
      return Order.new(:user_id => user_id, :deal_id => deal_id)
    end
  end
  
  # try to reserve the quantity of coupons
  def reserve_quantity(quantity)
    quantity = quantity.to_i
    begin
      Deal.transaction do
        deal = Deal.find(self.deal.id, :lock => true)
        
        if deal.coupon_count + quantity <= deal.max
          self.update_attributes!(:quantity => quantity, :amount => quantity*deal.deal_price.to_f)
          return true
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      # do anything here?
    end
    return false
  end
  
  # create coupons - after payment confirmation
  def create_coupons(user_id)
    begin
      Order.transaction do
        deal = Deal.find(self.deal.id)
        if deal.deal_codes.size == 0
          for i in (1..self.quantity)
            Coupon.create!(:user_id => 1000, :deal_id => deal.id, :order_id => self.id)
          end        
        else
          for i in (1..self.quantity)
            dc = DealCode.find(:first, :conditions => ["deal_id = ? AND reserved = ?", deal.id, false], :lock => true)
            if dc
              Coupon.create!(:user_id => 1000, :deal_id => deal.id, :order_id => self.id, :deal_code => dc.id)
              dc.update_attribute!(:reserved => true)
            end
          end
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      # do anything here?
    end
    return false
  end

end
