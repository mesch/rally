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
    @app_url = 'http://apps.facebook.com/rc_deals/'
    render :layout => false
  end
  
end