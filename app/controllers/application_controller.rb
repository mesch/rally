require "facebook"
require "subdomain"

class ApplicationController < ActionController::Base
  before_filter :set_p3p
  before_filter :set_merchant_subdomains
  protect_from_forgery

  include Facebook
  include DateHelper
  include ErrorHelper
  include SubdomainHelper
  include SslRequirement

  ### Subdomain methods
  def set_merchant_subdomains
    @merchant_subdomain = MerchantSubdomain.find_by_subdomain(request.subdomain)
    # if not a known subdomain - redirect to 'www'
    unless @merchant_subdomain
      redirect_to_subdomain('www')
    end
  end
  
  ### SSL methods
  def ssl_required?
    # always return false for tests
    return false if Rails.env.test?

    # otherwise, use the filters.
    super
  end

  ### Merchant methods
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
  
  def require_terms
    if @current_merchant
      if @current_merchant.terms
        return true
      else
        redirect_to :controller => "merchant", :action => "accept_terms"
        return false
      end
    else
      redirect_to :controller => "merchant", :action => "login"
      return false
    end
  end

  
  ### User methods
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
      # We found a user... Set them in the session
      set_user(user)
      return true
    end
    return false
  end
    
  # Checks the sessin for a user
  def get_user()  
    # Short circuit user with a session user if they exist
    if session[:user_id]
      return User.find_by_id(session[:user_id])
    end
    
    # Else see if there is a facebook connection...
    #fb_user = get_fb_user
    #if fb_user
    #  return User.find_by_facebook_id(fb_user["id"])
    #end
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
  
  # Redirect back to the url before login
  def redirect_user_to_stored
    if return_to = session[:user_return_to]
      session[:user_return_to]=nil
      redirect_to(return_to)
    else
      go_home
    end
  end

  ### Visitor methods
  # Sets session information for a visitor
  def check_for_visitor
    visitor_id = get_visitor_id
    
    if visitor_id
      set_visitor(visitor_id)
      return true
    end
    return false
  end

  # Gets the visitor_id 
  def get_visitor_id()
    # short circuit if already in the session
    visitor_id = session[:visitor_id]
    if visitor_id
      return visitor_id
    end
  
    # check cookies
    visitor_id = cookies['visitor_id']
    if visitor_id
      return visitor_id
    end
    
    # create a new visitor
    v = Visitor.new
    if v.save
      cookies['visitor_id'] = { :value => v.id, :expires => 180.days.from_now }
      return v.id
    end
    
    return nil
  end
  
  # Sets the session visitor information
  def set_visitor(visitor_id)
    if visitor_id
      session[:visitor_id] = visitor_id
      return true
    end
    return false
  end  
  
  ### Logging methods
  def log_user_action
    # only includes the final location (if redirected)
    unless response.location
      visitor_id = cookies['visitor_id']
      user_id = @current_user ? @current_user.id : nil
      merchant_id = @merchant_subdomain ? @merchant_subdomain.merchant_id : nil
      share_id = params[:share_id] ? params[:share_id] : nil
      if @deal
        deal_id = @deal.id
      elsif @order and @order.deal
        deal_id = @order.deal.id
      else
        deal_id = nil
      end
    
      ua = UserAction.delay(:priority=>10).log(:controller => self.controller_name, :action => self.action_name, :method => request.method,
        :visitor_id => visitor_id, :user_id => user_id, :merchant_id => merchant_id, :deal_id => deal_id, :share_id => share_id)
    end
  end
  
  private
  
  # this is required by IE so that we can set session cookies
  def set_p3p
    headers['P3P'] = 'CP="ALL DSP COR CURa ADMa DEVa OUR IND COM NAV"'
  end
    
end
