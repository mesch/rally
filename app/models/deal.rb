class Deal < ActiveRecord::Base
  validates_length_of :title, :maximum => 50
  validates_length_of :description, :maximum => 200
  validates_presence_of :merchant_id, :title, :start_date, :end_date, :expiration_date, :deal_price, :deal_value

  attr_protected :id

  money :deal_price, :currency => false
  money :deal_value, :currency => false

  belongs_to :merchant

  has_many :deal_images
  has_many :deal_codes
  
end
