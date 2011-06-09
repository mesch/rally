class UserController < ApplicationController
  before_filter :require_user, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :connect, :deals, :deal]
  before_filter :check_for_user, :only => [:deals, :deal]
  
  # Use the user layout
  layout "user"

  include Facebook
  
  def go_home
    redirect_to :controller => self.controller_name, :action => 'home'
  end
  
  def go_to_login
    redirect_to :controller => self.controller_name, :action => 'login'
  end
  
  # Deals
  def deals
    # TODO: Move this query into deal.rb? or user.rb?
    @deals = Deal.find(:all, :conditions => [ "published = ? AND start_date <= ? AND end_date >= ?", true, Time.zone.today, Time.zone.today])
    render "user/#{self.action_name}"
  end
  
  def deal
    @deal = Deal.find_by_id(params[:id])
    @now = Time.zone.now.to_f.round
    @diff = @deal.time_left
    @time_left = Deal.time_difference_for_display(@diff)
    if @current_user
      @order = @current_user.unconfirmed_order(@deal.id)
    end
    
    if !@deal.is_tipped
      @bar_size = (190*(@deal.confirmed_coupon_count/@deal.min.to_f)).ceil
      @bar_offset = (5*(@deal.confirmed_coupon_count/@deal.min.to_f)).ceil
    end
    
    # TODO: better query for other deals? Move into deal.rb? or user.rb?
    @others = Deal.find(
      :all, 
      :conditions => [ "published = ? AND start_date <= ? AND end_date >= ? AND id != ?", true, Time.zone.today, Time.zone.today, @deal.id], 
      :limit => 3)
    render "user/#{self.action_name}"
  end

  # Coupons
  def coupons
    @coupons = @current_user.coupons
    render "user/#{self.action_name}"
  end
  
  def coupon
    @coupon = Coupon.find_by_id(params[:id])
    render "user/#{self.action_name}"
  end

  
  def subscribe
    render "user/#{self.action_name}"
  end

  def invite
    render "user/#{self.action_name}"
  end

  def home
    # just go to deals, for now?
    redirect_to :controller => self.controller_name, :action => 'deals'
  end

  # Account methods
  def connect
    # Get the user from the facebook api
    fb = get_fb_user

    unless fb
      redirect_to :controller => self.controller_name, :action => 'login'
      return
    end
    
    # Try looking up by Facebook Id
    user = User.find_by_facebook_id(fb["id"])
    # Try looking up by Facebook Email
    unless user
      user = User.find_by_email(fb["email"])
    end
    # Try creating new user
    unless user
      user = User.new(:facebook_id => fb["id"], :first_name => fb["first_name"], :last_name => fb["last_name"], :email => fb["email"], :activated => true)
      user.password = user.password_confirmation = User.generate_password
      unless user.save
        logger.error "UserController.connect: Can't create User #{user}"
        redirect_to :controller => self.controller_name, :action => 'login'
        return
      end       
    end
    set_user(user)
    redirect_to :controller => self.controller_name, :action => 'home'
  end
  
  def account
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if @user.update_attributes(:first_name => params[:first_name], :last_name => params[:last_name])
        flash.now[:notice] = "Your account has been updated."
      else
        logger.error "User.account: Couldn't update User #{@user}"
        flash.now[:error] = "Could not update account. Please try again."
      end
    end
    render "user/#{self.action_name}"
  end

  def signup    
    unless @user
      @user = User.new()
    end
    if request.post?
      @user = User.new(:email => params[:email], :first_name => params[:first_name], :last_name => params[:last_name],
        :password => params[:password], :password_confirmation => params[:password_confirmation])
      # Check TOS
      unless params[:tos]     
        flash.now[:error] = "You must agree to the Terms of Service."
        render "user/#{self.action_name}"
        return
      end
      # Captcha validation
      unless verify_recaptcha(:private_key => OPTIONS[:recaptcha_private_key])      
        flash.now[:error] = "Invalid captcha results. Please try again."
        render "user/#{self.action_name}"
        return
      end
      if @user.save and @user.send_activation()
        flash[:notice] = "Signup successful. An activation code has been sent."
        redirect_to :controller => self.controller_name, :action =>'login'
        return
      else
        logger.error "User.signup: Couldn't create User #{@user}"
        flash.now[:error] = "Signup unsuccessful."
        render "user/#{self.action_name}"
      end
    end
  end

  def login
    @user = User.new()
    if request.post?
      u = User.authenticate(params[:email], params[:password])
      if u.nil?
        flash.now[:error] = "Login unsuccessful."
      else
        if u.active
          if u.activated
            session[:user_id] = u.id
            redirect_user_to_stored
            return
          else
            flash[:error] = "You must activate your account."
            redirect_to :controller => self.controller_name, :action => :reactivate
            return
          end
        else
          flash.now[:error] = "Your account is no longer active. Please contact customer support."
        end
      end
    end
    render "user/#{self.action_name}"
  end

  def logout
    @current_user = nil
    reset_session
    redirect_to :controller => self.controller_name, :action => 'login'
  end

  def forgot_password
    if request.post?
      u = User.find_by_email(params[:email])
      if u and u.send_new_password
        flash[:notice]  = "A new password has been sent."
        redirect_to :controller => self.controller_name, :action =>'login'
        return
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid email."
      end
    end
    render "user/#{self.action_name}"
  end

  def change_password
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if params[:password].blank?
        flash[:error] = "Passwords cannot be empty."
        redirect_to :controller => self.controller_name, :action => 'change_password'
        return
      else
        @user.update_attributes(:password => params[:password], :password_confirmation => params[:password_confirmation])
        if @user.save
          flash[:notice] = "Password changed."
          redirect_to :controller => self.controller_name, :action => 'account'
          return
        else
          logger.error "User.change_password: Couldn't update password for User #{@user}"
          flash[:error] = "Password not changed. Passwords must be at least 3 characters and match the confirmation field."
          redirect_to :controller => self.controller_name, :action => 'change_password'
          return
        end
      end
    end
    render "user/#{self.action_name}"
  end
  
  def change_email
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if @user.update_email(params[:email])
        flash[:notice]  = "Your email has been updated."
        redirect_to :controller => self.controller_name, :action => 'logout'
        return
      else
        logger.error "User.change_email: Couldn't update email for User #{@user}"
        flash.now[:error]  = "Could not update email. Please try again."
      end
    end
    render "user/#{self.action_name}"
  end
  
  def activate
    if params[:activation_code].blank? or params[:user_id].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller => self.controller_name, :action => :reactivate
      return
    else      
      activation_code = params[:activation_code] 
      user = User.find(:first, :conditions => {:id => params[:user_id]})
      if user && user.active && activation_code == user.activation_code
        # Activate the user
        user.activate
        flash[:notice] = "Congratulations! Your account is now active. Please login."
        redirect_to :controller => self.controller_name, :action => :login
        return
      else 
        flash[:error]  = "Invalid activation code. Maybe you've already activated. Try signing in."
        redirect_to :controller => self.controller_name, :action => :login
        return
      end
    end
  end
  
  def reactivate
    if request.post?
      u = User.find(:first, :conditions => {:email => params[:email]})
      if u and u.send_activation
        flash[:notice]  = "An activation code has been sent by email."
        redirect_to :controller => self.controller_name, :action =>'login'
        return
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid email."
      end
    end
    render "user/#{self.action_name}"   
  end
  
end