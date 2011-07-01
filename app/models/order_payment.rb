require 'authorize_net'
require "exception"

class OrderPayment < ActiveRecord::Base
  validates_presence_of :user_id, :order_id, :gateway, :amount

  attr_protected :id

  belongs_to :order
  belongs_to :user

  money :amount, :currency => false

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :order => 'created_at desc'
  end

  def capture!
    if self.gateway == OPTIONS[:gateways][:authorize_net] and (self.transaction_type == 'auth_only' or self.transaction_type == 'AUTH_ONLY')
      transaction = AuthorizeNet::AIM::Transaction.new(AUTHORIZE_NET_CONFIG['api_login_id'], AUTHORIZE_NET_CONFIG['api_transaction_key'])
      response = transaction.capture(self.amount.to_s, self.confirmation_code)
      if response.success?
        # update order payment
        self.update_attributes!(:transaction_type => 'capture_only')
      else
        logger.warn "OrderPayment.capture!: CAPTURE_ONLY failed for Order Payment #{self}"
        p "AUTHORIZE.NET: AUTH_ONLY FAILED."
        raise PaymentError, "AUTHORIZE.NET: AUTH_ONLY FAILED."
      end
    else
      # skipping everything else for now
      logger.warn "OrderPayment.capture!: Skipped Order Payment #{self}"
      p "SKIPPED ORDER PAYMENT."
      raise PaymentError, "SKIPPED ORDER PAYMENT."
    end
  end

end
