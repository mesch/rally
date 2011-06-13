class FacebookPaymentController < PaymentController
  before_filter :set_merchant
  skip_before_filter :verify_authenticity_token
  
  layout "facebook"
  
  def go_home
    redirect_to :controller => 'facebook', :action => 'home'
  end
  
  def go_to_login
    redirect_to :controller => 'facebook', :action => 'login'
  end
  
  def next_controller
    "facebook"
  end
  
  def set_merchant
    if session[:fb_page_id]
      @merchant = Merchant.find_by_facebook_page_id(session[:fb_page_id])
    end
  end
  
end