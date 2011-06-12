class FacebookController < UserController
  skip_before_filter :verify_authenticity_token
  
  layout "facebook"
  
  def go_home
    redirect_to :controller => self.controller_name, :action => 'home'
  end
  
  def go_to_login
    redirect_to :controller => self.controller_name, :action => 'login'
  end
  
  def splash
    if params[:signed_request]
      p params[:signed_request]
      signed_request = parse_signed_request(params[:signed_request])
      if signed_request and signed_request["page"] and signed_request["page"]["id"]
        fb_page_id = signed_request["page"]["id"]
      end
    end
    
    session[:fb_page_id] = fb_page_id
    @app_url = OPTIONS[:facebook_app_url]
    render :layout => false
  end
  
  def deals
    super(:merchant_id => 902541635)
  end
  
  def coupons
    super(:merchant_id => 902541635)
  end
  
end