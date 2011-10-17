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
        params.delete(:sd)
        redirect_to_subdomain(merchant_subdomain.subdomain, params)
      end
    end
  end
  
  def go_home
    redirect_to :controller => self.controller_name, :action => 'home'
  end
  
  def go_to_login
    redirect_to :controller => self.controller_name, :action => 'login'
  end
  
  def home
    # go directly to deal page - if deal_id is passed in
    if params[:deal_id]
      redirect_to :controller => self.controller_name, :action => 'deal', :id => params[:deal_id]
    else
      super
    end
  end
    
  def splash
    @app_url = OPTIONS[:facebook_app_url]
    
    if params[:signed_request]
      signed_request = parse_signed_request(params[:signed_request])
      #p signed_request
      if signed_request and signed_request["page"] and signed_request["page"]["id"]
        facebook_page_id = signed_request["page"]["id"]
        if merchant = Merchant.find_by_facebook_page_id(facebook_page_id)
          @merchant_subdomain = MerchantSubdomain.find_by_merchant_id(merchant.id)
          #p @merchant_subdomain
          if @merchant_subdomain
            @app_url += "?sd=#{@merchant_subdomain.subdomain}"
            
            # TODO: Move this query into deal.rb? or user.rb?
            @deals = Deal.find(:all, :conditions => [ "published = ? AND start_date <= ? AND end_date >= ?", true, Time.zone.today, Time.zone.today])

            # filter out other merchants if on a merchant subdomain
            if @merchant_subdomain and @merchant_subdomain.merchant
              @deals.delete_if {|deal| deal.merchant_id != @merchant_subdomain.merchant.id}
            end
            
          end
        end
      end
    end
    
    render :layout => false
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