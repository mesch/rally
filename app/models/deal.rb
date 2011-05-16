class Deal < ActiveRecord::Base
  validates_length_of :title, :maximum => 50
  validates_length_of :description, :maximum => 200
  validates_length_of :terms, :maximum => 200
  validates_presence_of :merchant_id, :title, :start_date, :end_date, :expiration_date, :deal_price, :deal_value
  validates_numericality_of :min, :greater_than_or_equal_to => 0
  validates_numericality_of :max, :greater_than_or_equal_to => 0
  validates_numericality_of :limit, :greater_than_or_equal_to => 0 

  attr_protected :id

  money :deal_price, :currency => false
  money :deal_value, :currency => false

  belongs_to :merchant

  has_many :deal_images
  has_many :deal_codes
  has_many :coupons

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

  def coupon_count
    count = Order.sum(:quantity, :conditions => ["deal_id = ?", self.id])
  end

  def is_tipped(coupon_count=nil)
    if self.min == 0
      return true
    end
    
    unless coupon_count
      coupon_count = self.coupon_count
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
  
end
