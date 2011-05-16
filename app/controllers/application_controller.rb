require "facebook"

class ApplicationController < ActionController::Base
  protect_from_forgery

  # Merchant methods
  def require_merchant
    if session[:merchant_id]
      @current_merchant = Merchant.find(session[:merchant_id])
      Time.zone = @current_merchant.time_zone
      return true
    end
    session[:merchant_return_to] = request.path
    redirect_to :controller => "merchant", :action => "login"
    return false 
  end

  def redirect_merchant_to_stored
    if return_to = session[:merchant_return_to]
      session[:merchant_return_to]=nil
      redirect_to(return_to)
    else
      redirect_to :controller=>'merchant', :action=>'home'
    end
  end
  
  # User methods
  def require_user
    if session[:user_id]
      @current_user = User.find(session[:user_id])
      Time.zone = @current_user.time_zone
      return true
    end
    flash[:notice] = "Login required."
    session[:user_return_to] = request.path
    redirect_to :controller => "user", :action => "login"
    return false 
  end

  def redirect_user_to_stored
    if return_to = session[:user_return_to]
      session[:user_return_to]=nil
      redirect_to(return_to)
    else
      redirect_to :controller=>'user', :action=>'home'
    end
  end
  
  def set_user
    if session[:user_id]
      @current_user = User.find(session[:user_id])
      Time.zone = @current_user.time_zone
      return true
    end
    return false
  end
  
## FB-related user methods
=begin
  def require_user
    # Require that one of users is in the session
    
    # Get the user if they exist
    user = get_user
    p user
    
    if user
      # We found a user... Set them in the session
      set_user(user)
    else
      # No user.. redirect to login
      redirect_to user_login_url
    end
  end
    
  # Gets the fb user and checks if they exist in our system
  def get_user    
    # Make sure there is a facebook connection...
    fb_user = get_fb_user
    p fb_user
    return unless fb_user
        
    # Short circuit user with a session user if they exist
    return User.find(session[:user_id]) if session[:user_id]
        
    # Find the base user and use them
    User.find_by_facebook_id(fb_user["id"])  
  end
=end

  # Helper methods
  def verify_date(string)
    begin
      return Time.zone.parse(string) ? true : false
    rescue
      return false
    end
  end

end
