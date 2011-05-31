class Order < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :quantity, :amount
  validates_inclusion_of :state, :in => [OPTIONS[:order_states][:created], OPTIONS[:order_states][:authorized], OPTIONS[:order_states][:paid]]
  
  money :amount, :currency => false
  
  belongs_to :deal
  belongs_to :user
  has_many :order_payments
  
  # try to reserve the quantity of coupons
  def reserve_quantity(quantity)
    quantity = quantity.to_i
    begin
      Deal.transaction do
        deal = Deal.find(self.deal.id, :lock => true)
        
        if deal.max == 0 or deal.coupon_count + quantity - self.quantity <= deal.max
          self.update_attributes!(:quantity => quantity, :amount => quantity*deal.deal_price.to_f, :updated_at => Time.zone.now)
          return true
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.reserce_quantity: Failed for Order #{self}", invalid
    end
    return false
  end
  
  # update db - after successful authorization
  def process_authorization(options)
    gateway = options[:gateway]
    transaction_type = options[:transaction_type]
    amount = options[:amount]
    confirmation_code = options[:confirmation_code]
    begin
      Order.transaction do
        # lock order
        Order.find_by_id(self.id, :lock => true)
        # create order_payment
        OrderPayment.create!(:user_id => self.user_id, :order_id => self.id, :gateway => gateway, 
          :transaction_type => transaction_type, :confirmation_code => confirmation_code, :amount => amount)
        # create coupons
        self.create_coupons!
        # update order
        self.update_attributes!(:state => OPTIONS[:order_states][:authorized])
      end
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.process_authorization: Failed for Order #{self}", invalid
    end
    return false
  end
  
  # create coupons - after successful authorization
  def create_coupons!()
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
  
  #  'capture_only' after a previous 'auth_only' transaction
  def capture
    begin 
      Order.transaction do
        # lock order
        Order.find_by_id(self.id, :lock => true)
        # go through all order_payments
        order_payments = self.order_payments
        for order_payment in order_payments
          order_payment.capture!
        end
        # update order
        self.update_attributes!(:state => OPTIONS[:order_states][:paid])
      end
    rescue RuntimeError => e
      logger.error "Order.capture: Failed for Order #{self}", e
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.capture: Failed for Order #{self}", invalid
    end
  end
  
  def is_timed_out(timeout=nil)
    unless timeout
      timeout = OPTIONS[:order_timeout]
    end
    
    updated_at = self.updated_at
    # force update for next checks
    self.update_attributes(:updated_at => Time.zone.now)
    
    # check updated_at
    if updated_at < Time.zone.now - timeout.seconds
      return true
    end
    return false
  end

  # Reset quantity and amount (to 0) for unconfirmed orders that have timed out
  def self.reset_orders(timeout=nil)
    unless timeout
      # add some buffer (5 mins)
      timeout = OPTIONS[:order_timeout] + 5*60
    end
    
    begin
      Order.transaction do
        # select order and lock until all are updated
        orders = Order.find(:all, :conditions => ["updated_at < ? AND state = ? AND quantity > 0", 
          Time.zone.now - (timeout.seconds), OPTIONS[:order_states][:created]], :lock => true)
		    # set quantity to 0, amount to 0
		    for order in orders
		      order.update_attributes!(:quantity => 0, :amount => 0)
        end
        logger.info "#{orders.size} orders reset."
      end
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.rest_orders: ", invalid
    end
  end

end
