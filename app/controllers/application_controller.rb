require "facebook"

class ApplicationController < ActionController::Base
  before_filter :set_merchant_subdomains
  protect_from_forgery

  include Facebook
  include DateHelper
  include SslRequirement

  # Subdomain
  def set_merchant_subdomains
    @merchant_subdomain = MerchantSubdomain.find_by_subdomain(request.subdomain)
  end

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
  # Require that a user is present
  def require_user
    # Get the user if they exist
    user = get_user
    
    if user
      # We found a user... Set them in the session
      set_user(user)
      return true
    else
      # No user.. redirect to login
      session[:user_return_to] = request.path
      go_to_login
    end
    return false
  end
  
  # Sets session information if a user is present
  def check_for_user
    user = get_user
    if user
      set_user(user)
      return true
    end
    return false
  end
    
  # Gets the fb user and checks if they exist in our system
  def get_user()  
    # Short circuit user with a session user if they exist
    if session[:user_id]
      return User.find_by_id(session[:user_id])
    end
    
    # Else see if there is a facebook connection...
    fb_user = get_fb_user
    if fb_user
      return User.find_by_facebook_id(fb_user["id"])
    end
    return nil 
  end
  
  # Sets the session information
  def set_user(user)
    if user
      @current_user = user
      session[:user_id] = user.id
      Time.zone = @current_user.time_zone
      return true
    end
    return false
  end
  
  def redirect_user_to_stored
    if return_to = session[:user_return_to]
      session[:user_return_to]=nil
      redirect_to(return_to)
    else
      go_home
    end
  end

  def ssl_required?
    # (Comment this one line out if you want to test ssl locally)
    #return false if local_request? 

    # always return false for tests
    return false if RAILS_ENV == 'test'

    # otherwise, use the filters.
    super
  end
  

end
