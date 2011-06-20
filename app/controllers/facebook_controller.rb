class FacebookController < UserController
  skip_before_filter :verify_authenticity_token
  ssl_allowed :home
  
  layout "facebook"
  
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
  
  def home
    # merchant connect - any better way to tell?
    if params[:fb_page_id] and !Merchant.find_by_facebook_page_id(params[:fb_page_id])
      redirect_to :controller => 'merchant', :action => 'connect', :fb_page_id => params[:fb_page_id]
      return
    end
    
    # check for subdomain passed in
    if params[:sd] and merchant_subdomain = MerchantSubdomain.find_by_subdomain(params[:sd]) and merchant_subdomain.merchant_id
      redirect_to :host => "#{params[:sd]}." + request.host_with_port, :controller => self.controller_name, :action => self.action_name, :sd => nil
      return
    end
    
    super
  end
  
end