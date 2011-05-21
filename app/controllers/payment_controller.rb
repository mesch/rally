class PaymentController < ApplicationController
  before_filter :require_user, :except => [ ]

  layout "user"
  helper :authorize_net
  protect_from_forgery :except => :relay_response  
  
  
  def go_home
    redirect_to :controller => 'user', :action => 'home'
  end
  
  # order form
  def order
    # number of checks to see if coming out of context
    # no deal_id
    unless params[:deal_id]
      go_home()
      return
    end
    @deal = Deal.find_by_id(params[:deal_id])
    # deal doesn't exist
    unless @deal
      go_home()
      return
    end
    
    # check if deal has ended
    if @deal.is_ended
      flash[:notice] = "This deal has ended. Checkout out some of our other deals!"
      redirect_to :controller => 'user', :action => 'home'
      return
    end
    
    # find (or create) an unconfirmed order
    @order = @current_user.unconfirmed_order(@deal.id)

    @limit = @deal.limit
    @quantity = @order.quantity != 0 ? @order.quantity : 1

    if request.post?
      quantity = params[:quantity].to_i
      if quantity != 0
        # try to reserve the quantity - update order
        if @order.reserve_quantity(quantity)
          redirect_to :controller => 'payment', :action => 'purchase', :order_id => @order.id
        else
          flash.now[:error] = "There are not enough coupons available. Reduce your quantity and try again."
        end
      else
        flash.now[:error] = "Select at least one coupon."
      end
    end
  end


  # GET
  # Displays a purchase form.
  def purchase
    # number of checks to see if coming out of context
    # no order_id
    unless params[:order_id]
      go_home()
      return
    end
    @order = Order.find_by_id(params[:order_id])
    # order doesn't exist
    unless @order
      go_home()
      return
    end
    # order is already confirmed
    if @order.confirmation_code
      go_home()
      return
    end
    # order has zero quantity or zero amount
    if @order.quantity == 0 or @order.amount == 0
      go_home()
      return
    end
    # deal doesn't exist
    deal = @order.deal
    unless deal
      go_home()
      return
    end
    
    # check if deal has ended
    if deal.is_ended
      flash[:notice] = "This deal has ended. Checkout out some of our other deals!"
      redirect_to :controller => 'user', :action => 'home'
      return
    end
    
    # check if order is timed out
    if @order.is_timed_out
      flash[:error] = "Your order has timed out. Please restart your transaction."
      redirect_to :controller => 'payment', :action => 'order', :deal_id => @order.deal.id
      return
    end
    
    @sim_transaction = 
      AuthorizeNet::SIM::Transaction.new(
        AUTHORIZE_NET_CONFIG['api_login_id'], 
        AUTHORIZE_NET_CONFIG['api_transaction_key'], 
        @order.amount.to_f, 
        :relay_url => payment_relay_response_url(:only_path => false))
    @timeout = OPTIONS[:order_timeout]
  end

  # POST
  # Returns relay response when Authorize.Net POSTs to us.
  def relay_response
    p params
    p params[:x_invoice_num]
    sim_response = AuthorizeNet::SIM::Response.new(params)
    p sim_response
    if sim_response.success?(AUTHORIZE_NET_CONFIG['api_login_id'], AUTHORIZE_NET_CONFIG['merchant_hash_value'])
      render :text => sim_response.direct_post_reply(payment_receipt_url(:only_path => false), :include => true)
    else
      flash[:notice] = "There was a problem approving your transaction. Please try again."
      redirect_to :controller => "payment", :action => "purchase", :order_id => params[:x_invoice_num]
    end
  end
  
  # GET
  # Displays a receipt.
  def receipt
    p params
    p params[:x_invoice_num]
    @order = Order.find_by_id(params[:x_invoice_num])
    @auth_code = params[:x_auth_code]
    # create coupons 
    unless @order.update_attribute(:confirmation_code => @auth_code) and @order.create_coupons() 
      flash.now[:error] = "Your transaction was approved. However, there was a problem creating your coupons. Please contact Customer Service."
    end
  end

end