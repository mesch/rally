class PaymentsController < ApplicationController
  before_filter :require_user, :except => [ ]
  # add a filter to check status of the deal?

  layout "user"
  helper :authorize_net
  protect_from_forgery :except => :relay_response

  # GET
  # Displays a payment form.
  def payment
    @order = Order.find(params[:order_id])
    @sim_transaction = 
      AuthorizeNet::SIM::Transaction.new(
        AUTHORIZE_NET_CONFIG['api_login_id'], 
        AUTHORIZE_NET_CONFIG['api_transaction_key'], 
        @order.amount.to_f, 
        :relay_url => payments_relay_response_url(:only_path => false))
  end

  # POST
  # Returns relay response when Authorize.Net POSTs to us.
  def relay_response
    sim_response = AuthorizeNet::SIM::Response.new(params)
    if sim_response.success?(AUTHORIZE_NET_CONFIG['api_login_id'], AUTHORIZE_NET_CONFIG['merchant_hash_value'])
      render :text => sim_response.direct_post_reply(payments_receipt_url(:only_path => false), :include => true)
    else
      render
    end
  end
  
  # GET
  # Displays a receipt.
  def receipt
    p params
    p params[:x_invoice_num]
    @order = Order.find(params[:x_invoice_num])
    @auth_code = params[:x_auth_code]
    # create coupons 
    unless @order.update_attribute(:confirmation_code => @auth_code) and @order.create_coupons(@current_user.id) 
      flash.now[:error] = 'Your transaction was approved. However, there was a problem creating your coupons. Please contact Customer Service.'
    end
  end

end