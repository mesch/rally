class Deal < ActiveRecord::Base
  validates_length_of :title, :maximum => 50
  validates_length_of :description, :maximum => 2000
  validates_length_of :terms, :maximum => 2000
  validates_presence_of :merchant_id, :title, :start_date, :end_date, :expiration_date, :deal_price, :deal_value
  validates_numericality_of :min, :greater_than_or_equal_to => 0
  validates_numericality_of :max, :greater_than_or_equal_to => 0
  validates_numericality_of :limit, :greater_than_or_equal_to => 0 
  validates_numericality_of :deal_price, :greater_than_or_equal_to => 1
  validates_numericality_of :deal_value, :greater_than_or_equal_to => 1

  attr_protected :id

  money :deal_price, :currency => false
  money :deal_value, :currency => false

  belongs_to :merchant

  has_many :deal_images
  has_one :deal_video
  has_many :deal_codes
  has_many :coupons
  has_many :shares

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ['title like ?', "%#{search}%"],
             :order => 'created_at desc'
  end
  
  # format for sharing in facebook
  def facebook_share(deal_url)
    response = { 
      :id => self.id,
	    :name  => self.title,
	    :caption => self.merchant.name,
	    :description => self.description, 
	    :picture => self.deal_images.size > 0 ? self.deal_images[0].image.url : '',
	    :url => deal_url
	  }
	  return response
  end
  
  def discount
    if self.deal_value == 0
      return 0
    end
    return (self.savings * 100 / self.deal_value).round
  end
  
  def savings
    return self.deal_value - self.deal_price
  end
  
  def deal_images
    return DealImage.find(:all, :conditions => {:deal_id => self.id}, :order => "counter ASC")
  end

  # returns number of all coupons - whether or not they have been authorized
  def coupon_count
    count = Order.sum(:quantity, :conditions => ["deal_id = ?", self.id])
  end
  
  # returns number of all authorized coupons
  def confirmed_coupon_count
    count = Order.sum(:quantity, :conditions => ["deal_id = ? AND state != ?", self.id, Order::CREATED])
  end
  
  def publish
    begin
      Deal.transaction do
        # If there are deal_codes - set max to the count
        max = self.deal_codes.size != 0 ? self.deal_codes.size : self.max
        self.update_attributes!(:published => true, :max => max)      
      end
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Deal.publish: Failed for Deal #{self.inspect} #{invalid}"
    end
    return false
  end

  def delete
    begin
      self.update_attributes!(:active => false)
      return true
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "Deal.delete: Failed for Deal #{self.inspect} #{invalid}"
    end
    return false
  end
  
  def force_tip
    if self.min > self.confirmed_coupon_count
      begin
        self.update_attributes!(:min => self.confirmed_coupon_count)
        return true
      rescue ActiveRecord::RecordInvalid => invalid
        logger.error "Deal.force_tip: Failed for Deal #{self.inspect} #{invalid}"
      end
      return false
    end
    return true
  end

  def is_tipped(coupon_count=nil)
    if self.min == 0
      return true
    end
    
    unless coupon_count
      coupon_count = self.confirmed_coupon_count
    end

    if coupon_count >= self.min
      return true
    else
      return false
    end
  end

  def is_maxed(coupon_count=nil)
    if self.max == 0
      return false
    end
    
    unless coupon_count
      coupon_count = self.coupon_count
    end

    if coupon_count >= self.max
      return true
    else
      return false
    end
  end

  # datetime needs to have timezone information, i.e. Time.zone.now  
  def is_started(datetime=nil)
    unless datetime
      datetime = Time.zone.now
    end
    
    if self.start_date.to_date.beginning_of_day < datetime
      return true
    else
      return false
    end
  end

  # datetime needs to have timezone information, i.e. Time.zone.now  
  def is_ended(datetime=nil)
    unless datetime
      datetime = Time.zone.now
    end
    
    if self.end_date.to_date.end_of_day < datetime
      return true
    else
      return false
    end
  end
  
  # datetime needs to have timezone information, i.e. Time.zone.now
  def is_expired(datetime=nil)
    unless datetime
      datetime = Time.zone.now
    end
    
    if self.expiration_date.to_date.end_of_day < datetime
      return true
    else
      return false
    end
  end
  
  # datetime needs to have timezone information, i.e. Time.zone.now  
  def time_left(datetime=nil)
    unless datetime
      datetime = Time.zone.now
    end    
    
    # weird rounding issue with the time difference?
    return (self.end_date.to_date.end_of_day - datetime).round
  end
  
  # splits up a time difference (in seconds) into a hash:
  #   {:days => days, :hours => hours, :minutes => minutes, :seconds => seconds}
  def self.time_difference_for_display(difference)
    if difference < 0
      difference *= -1
      multiplier = -1
    end
    
    seconds     =  difference % 60
    difference  = (difference - seconds) / 60
    minutes     =  difference % 60
    difference  = (difference - minutes) / 60
    hours       =  difference % 24
    days        = (difference - hours)   / 24
    
    if multiplier
      days *= multiplier
      hours *= multiplier
      minutes *= multiplier
      seconds *= multiplier
    end

    return {:days => days, :hours => hours, :minutes => minutes, :seconds => seconds}
  end
  
  def self.charge_orders
    considered = 0
    successes = 0
    failures = 0
    # select all deals - tipped, not expired
    deals = Deal.find(:all, :conditions => ["expiration_date >= ?", Time.zone.today])
    for deal in deals
      #p "Checking Deal #{deal.inspect}"
      if deal.is_tipped
        #p "  is tipped..."
        begin
          Deal.transaction do
            # charge any authorized orders
            orders = Order.find(:all, :conditions => ["deal_id = ? AND state = ?", deal.id, Order::AUTHORIZED], :lock => true)
            considered += orders.length
            for order in orders
              #p "  Trying to capture Order #{order.inspect}"
              order.update_attributes(:state => Order::PAYING)
              order.delay(:priority=>20).capture
            end
          end
        rescue ActiveRecord::RecordInvalid => invalid
          logger.error "Deal.charge_orders: Failed for Deal #{deal.inspect} #{invalid}"
        end
      end
    end
    return { :considered => considered, :successes => successes, :failures => failures }
  end
  
  # Deal statistics methods
  def views_in_date_range(start_time, end_time)
    return UserAction.count(
      :conditions => ["controller = ? AND action = ? AND deal_id = ? AND created_at >= ? AND created_at <= ?", 
        "user", "deal", self.id, start_time, end_time])
  end
  
  def orders_in_date_range(start_time, end_time)
    return Order.count(:conditions => ["deal_id = ? AND authorized_at >= ? AND authorized_at <= ?", self.id, start_time, end_time])
  end
  
  def coupons_in_date_range(start_time, end_time)
    return Coupon.count(:conditions => ["deal_id = ? AND created_at >= ? AND created_at <= ?", self.id, start_time, end_time])
  end
  
  def shares_in_date_range(start_time, end_time)
    return Share.count(:conditions => ["deal_id = ? AND posted = ? AND created_at >= ? AND created_at <= ?", self.id, true, start_time, end_time])
  end
  
end
