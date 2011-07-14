require "exception"

class Order < ActiveRecord::Base
  validates_presence_of :user_id, :deal_id, :quantity, :amount
  validates_inclusion_of :state, :in => [OPTIONS[:order_states][:created], OPTIONS[:order_states][:authorized], OPTIONS[:order_states][:paid]]
  
  money :amount, :currency => false
  
  attr_protected :id
  
  belongs_to :deal
  belongs_to :user
  has_many :order_payments

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ["quantity != 0"],
             :order => 'created_at desc'
  end
  
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
      logger.error "Order.reserce_quantity: Failed for Order #{self.inspect}", invalid
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
        # ignore any order state besides created - page refresh
        if self.state == OPTIONS[:order_states][:created]
          # create order_payment
          OrderPayment.create!(:user_id => self.user_id, :order_id => self.id, :gateway => gateway, 
            :transaction_type => transaction_type, :confirmation_code => confirmation_code, :amount => amount)
          # create coupons
          self.create_coupons!
          # update order
          self.update_attributes!(:state => OPTIONS[:order_states][:authorized], :authorized_at => Time.zone.now)
        end
      end
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.process_authorization: Failed for Order #{self.inspect}", invalid
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
        if order_payments.size == 0
          p "No order_payments to process."
          raise PaymentError, "No order_payments to process."
        end
        for order_payment in order_payments
          order_payment.capture!
        end
        # update order
        self.update_attributes!(:state => OPTIONS[:order_states][:paid], :paid_at => Time.zone.now)
      end
      return true
    rescue PaymentError => pe
      p "Order.capture: Failed for Order #{self.inspect} #{pe}"
      logger.error "Order.capture: Failed for Order #{self.inspect}", pe
    rescue ActiveRecord::RecordInvalid => invalid
      p "Order.capture: Failed for Order #{self.inspect} #{invalid}"
      logger.error "Order.capture: Failed for Order #{self.inspect}", invalid
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
    if updated_at < Time.zone.now - timeout.seconds
      return true
    end
    return false
  end

  # Reset quantity and amount (to 0) for unconfirmed orders that have timed out
  def self.reset_orders(timeout=nil)
    considered = 0
    successes = 0
    failures = 0
    unless timeout
      # add some buffer (5 mins)
      timeout = OPTIONS[:order_timeout] + 5*60
    end
    
    Order.transaction do
      # select order and lock until all are updated
      orders = Order.find(:all, :conditions => ["updated_at < ? AND state = ? AND quantity > 0", 
        Time.zone.now - (timeout.seconds), OPTIONS[:order_states][:created]], :lock => true)
      considered = orders.length
	    # set quantity to 0, amount to 0
	    for order in orders
	      p "Resetting Order #{order.inspect}"
	      if order.update_attributes(:quantity => 0, :amount => 0)
	        successes += 1
	      else
	        failures += 1
	      end
      end
      logger.info "#{orders.size} orders reset."
    end
    return {:considered => considered, :successes => successes, :failures => failures}
  end

end
