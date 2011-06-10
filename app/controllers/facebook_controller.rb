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
      @signed_request = parse_signed_request(params[:signed_request])
    end
    p @signed_request
    @app_url = OPTIONS[:facebook_ap_url]
    render :layout => false
  end
  
end