require "exception"

class Order < ActiveRecord::Base
  # States
  CREATED = 'CREATED'
  AUTHORIZED = 'AUTHORIZED'
  PAYING = 'PAYING'
  PAID = 'PAID'

  validates_presence_of :user_id, :deal_id, :quantity, :amount
  validates_inclusion_of :state, :in => [ CREATED, AUTHORIZED, PAYING, PAID ]
  
  money :amount, :currency => false
  
  attr_protected :id
  
  belongs_to :deal
  belongs_to :user
  has_many :order_payments
  has_many :coupons

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
      logger.error "Order.reserce_quantity: Failed for Order #{self.inspect} #{invalid}"
    end
    return false
  end
  
  # update db - after successful authorization
  def process_authorization(options)
    gateway = options[:gateway]
    transaction_type = options[:transaction_type]
    amount = options[:amount]
    confirmation_code = options[:confirmation_code]
    transaction_id = options[:transaction_id]
    begin
      Order.transaction do
        # lock order
        Order.find_by_id(self.id, :lock => true)
        # ignore any order state besides created - page refresh
        if self.state == Order::CREATED
          # create order_payment
          OrderPayment.create!(:user_id => self.user_id, :order_id => self.id, :gateway => gateway, 
            :transaction_type => transaction_type, :confirmation_code => confirmation_code, 
            :transaction_id => transaction_id, :amount => amount)
          # create coupons
          self.create_coupons!
          # update order
          self.update_attributes!(:state => Order::AUTHORIZED, :authorized_at => Time.zone.now)
        end
      end
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Order.process_authorization: Failed for Order #{self.inspect} #{invalid}"
    end
    return false
  end
  
  # create coupons - after successful authorization
  def create_coupons!()
    deal = Deal.find(self.deal.id)
    for i in (1..self.quantity)
      dc = DealCode.find(:first, :conditions => ["deal_id = ? AND reserved = ? AND incentive = ?", deal.id, false, false], :lock => true)
      if dc
        Coupon.create!(:user_id => self.user.id, :deal_id => deal.id, :order_id => self.id, :deal_code_id => dc.id)
        dc.update_attributes!(:reserved => true)
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
        self.upgrade_coupons!
        # update order
        self.update_attributes!(:state => Order::PAID, :paid_at => Time.zone.now)
      end
      # send confirmation email
      user = User.find_by_id(self.user_id)
      if user and user.send_confirmation(self.deal_id)
        return true
      else
        logger.error "Order.capture: Confirmation email failed to send: #{self.inspect}"
        return false
      end
    rescue PaymentError => pe
      p "Order.capture: Failed for Order #{self.inspect} #{pe}"
      logger.error "Order.capture: Failed for Order #{self.inspect} #{pe}"
    rescue ActiveRecord::RecordInvalid => invalid
      p "Order.capture: Failed for Order #{self.inspect} #{invalid}"
      logger.error "Order.capture: Failed for Order #{self.inspect} #{invalid}"
    end
    return false
  end
  
  # check if deal_incentive is met and upgrade coupons
  def upgrade_coupons!
    deal = Deal.find(self.deal.id)
    if deal.deal_incentive
      if deal.deal_incentive.is_accomplished(self.user.id)
        for coupon in self.coupons
          # check against max
          if deal.deal_incentive.max == 0 or deal.deal_incentive.reserved_codes_count + 1 <= deal.deal_incentive.max
            dc = DealCode.find(:first, :conditions => ["deal_id = ? AND reserved = ? AND incentive = ?", deal.id, false, true], :lock => true)
            if dc
              coupon.update_attributes!(:deal_code_id => dc.id)
              dc.update_attributes!(:reserved => true)
            end
          end
        end
      end
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
    considered = 0
    successes = 0
    failures = 0
    unless timeout
      # add some buffer (5 mins)
      timeout = OPTIONS[:order_timeout] + 5*60
    end
    
    begin
      Order.transaction do
        # select order and lock until all are updated
        orders = Order.find(:all, :conditions => ["updated_at < ? AND state = ? AND quantity > 0", 
          Time.zone.now - (timeout.seconds), Order::CREATED], :lock => true)
        considered = orders.length
  	    # set quantity to 0, amount to 0
  	    for order in orders
  	      #p "Resetting Order #{order.inspect}"
  	      if order.update_attributes(:quantity => 0, :amount => 0)
  	        successes += 1
  	      else
  	        failures += 1
  	      end
        end
      end
    rescue
      logger.error "Order.reset_orders: Failed #{invalid}"
    end
    
    return {:considered => considered, :successes => successes, :failures => failures}
  end

end
