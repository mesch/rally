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

  has_many :deal_incentive_codes
  
  def self.create_type_options
    return [['', nil], ['Share', DealIncentive::SHARE]]
    #return [['', nil], ['Share', DealIncentive::SHARE], ['Purchase', DealIncentive::PURCHASE]]
  end

end
