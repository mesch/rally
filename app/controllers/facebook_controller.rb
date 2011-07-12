class FacebookController < UserController
  prepend_before_filter :handle_subdomain, :only => [:home]
  skip_before_filter :verify_authenticity_token
  ssl_allowed :home
  
  layout "facebook"
  
  def handle_subdomain
    # check for subdomain passed in
    if params[:sd]
      merchant_subdomain = MerchantSubdomain.find_by_subdomain(params[:sd])
      if merchant_subdomain and merchant_subdomain.merchant_id and request.subdomain != merchant_subdomain.subdomain
        redirect_to_subdomain(merchant_subdomain.subdomain)
      end
    end
  end
  
  def go_home
    redirect_to :controller => self.controller_name, :action => 'home'
  end
  
  def go_to_login
    redirect_to :controller => self.controller_name, :action => 'login'
  end
  
  def splash
    @app_url = OPTIONS[:facebook_app_url]
    
    if params[:signed_request]
      signed_request = parse_signed_request(params[:signed_request])
      p signed_request
      if signed_request and signed_request["page"] and signed_request["page"]["id"]
        facebook_page_id = signed_request["page"]["id"]
        if merchant = Merchant.find_by_facebook_page_id(facebook_page_id)
          @merchant_subdomain = MerchantSubdomain.find_by_merchant_id(merchant.id)
          p @merchant_subdomain
          if @merchant_subdomain
            @app_url += "?sd=#{@merchant_subdomain.subdomain}"
          end
        end
      end
    end
    
    render :layout => false
  end
  
end