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
    return "facebook"
  end
  
  private
  
  def generate_deal_url(deal)
    # deal_url needs to be external url for facebook app
    deal_url = OPTIONS[:facebook_app_url] + "?deal_id=#{deal.id}"
    if merchant_subdomain = MerchantSubdomain.find_by_subdomain(request.subdomain)
      deal_url += "&sd=#{merchant_subdomain.subdomain}"
    end
    return deal_url
  end
  
end