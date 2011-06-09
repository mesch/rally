class FacebookPaymentController < PaymentController
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
  
end