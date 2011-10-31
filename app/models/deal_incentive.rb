class DealIncentive < ActiveRecord::Base
  SHARE = 'SHARE'
  PURCHASE = 'PURCHASE'

  validates_presence_of :deal_id, :metric_type, :incentive_price, :incentive_value, :number_required
  validates_numericality_of :max, :greater_than_or_equal_to => 0
  validates_numericality_of :number_required, :greater_than_or_equal_to => 1
  validates_numericality_of :incentive_price, :greater_than_or_equal_to => 1
  validates_numericality_of :incentive_value, :greater_than_or_equal_to => 1
  validates_inclusion_of :metric_type, :in => [ SHARE, PURCHASE ]
  validates_uniqueness_of :deal_id

  attr_protected :id

  money :incentive_price, :currency => false
  money :incentive_value, :currency => false

  belongs_to :deal
  
  def self.create_type_options
    return [['', nil], ['Share', DealIncentive::SHARE]]
    #return [['', nil], ['Share', DealIncentive::SHARE], ['Purchase', DealIncentive::PURCHASE]]
  end
  
  def added_value
    return self.incentive_value - self.deal.deal_value
  end
  
  def is_accomplished(user_id)
    if self.metric_type == DealIncentive::SHARE
      distinct_shares = Share.find(:all, :select => "DISTINCT(facebook_id)", :conditions => ["deal_id = ? AND user_id = ?", self.deal.id, user_id])
      if distinct_shares.size >= self.number_required
        return true
      end
    end
    return false
  end
  
  def reserved_coupons_count
    return DealCode.count(:conditions => ["deal_id = ? and incentive = ? and reserved =?", self.deal_id, true, true])
  end

end
