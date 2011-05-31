require 'authorize_net'

class OrderPayment < ActiveRecord::Base
  validates_presence_of :user_id, :order_id, :gateway, :amount

  belongs_to :order
  belongs_to :user

  money :amount, :currency => false

  def capture!
    if self.gateway == OPTIONS[:gateways][:authorize_net] and (self.transaction_type == 'auth_only' or self.transaction_type == 'AUTH_ONLY')
      transaction = AuthorizeNet::AIM::Transaction.new(AUTHORIZE_NET_CONFIG['api_login_id'], AUTHORIZE_NET_CONFIG['api_transaction_key'])
      response = transaction.capture(self.amount.to_s, self.confirmation_code)
      if response.success?
        # update order payment
        self.update_attributes!(:transaction_type => 'capture_only')
      else
        logger.warning "OrderPayment.capture!: CAPTURE_ONLY failed for Order Payment #{self}"
        raise "AUTHORIZE.NET: AUTH_ONLY FAILED"
      end
    else
      # skipping everything else for now
      logger.warning "OrderPayment.capture!: Skipped Order Payment #{self}"
      raise "SKIPPED ORDER PAYMENT"
    end
  end

end