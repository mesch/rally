class UserController < ApplicationController
  before_filter :require_user, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :deals, :deal]
  before_filter :set_user, :only => [:deals, :deal]
  
  # Use the user layout
  layout "user"

  # Deals
  def deals
    # Show all deals for now?
    @deals = Deal.find(:all)
  end
  
  def deal
    @deal = Deal.find_by_id(params[:id])
    p @deal
    p @deal.deal_images
    p @deal.deal_images[0]
    p @deal.deal_images[0].image.url
    @now = Time.zone.now.to_f.round
    @diff = @deal.time_left
    @time_left = Deal.time_difference_for_display(@diff)
    if @current_user
      @order = @current_user.unconfirmed_order(@deal.id)
    end
    
    # TODO: better query for other deals?
    @others = Deal.find(:all, :conditions => [ "id != ?", @deal.id], :limit => 3)
  end

  def home

  end

  # Account methods
  def account
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if @user.update_attributes(:first_name => params[:first_name], :last_name => params[:last_name], 
          :mobile_number => params[:mobile_number])
        flash.now[:notice] = "Your account has been updated."
      else
        flash.now[:error] = "Could not update account. Please try again."
      end
    end
  end

  def signup    
    unless @user
      @user = User.new()
    end
    if request.post?
      @user = User.new(:username => params[:username], :email => params[:email],
        :password => params[:password], :password_confirmation => params[:password_confirmation])
      # Check TOS
      unless params[:tos]     
        flash.now[:error] = "You must agree to the Terms of Service."
        render(:action => :signup)
        return
      end
      # Captcha validation
      unless verify_recaptcha(:private_key => OPTIONS[:recaptcha_private_key])      
        flash.now[:error] = "Invalid captcha results. Please try again."
        render(:action => :signup)
        return
      end
      if @user.save and @user.send_activation()
          flash[:notice] = "Signup successful. An activation code has been sent."
          redirect_to :controller => 'user', :action =>'login'
      else
        flash.now[:error] = "Signup unsuccessful."
        render(:action => :signup)
      end
    end
  end

  def login
    @user = User.new()
    if request.post?
      u = User.authenticate(params[:username], params[:password])
      if u.nil?
        flash.now[:error] = "Login unsuccessful."
      else
        if u.active
          if u.activated
            session[:user_id] = u.id
            redirect_user_to_stored
          else
            flash[:error] = "You must activate your account."
            redirect_to :controller => 'user', :action => :reactivate
          end
        else
          flash.now[:error] = "Your account is no longer active. Please contact customer support."
        end
      end
    end
  end

  def logout
    @current_user = nil
    reset_session
    redirect_to :controller => 'user', :action => 'login'
  end

  def forgot_password
    if request.post?
      u = User.find(:first, :conditions => {:username => params[:username]})
      if u.nil?
        u = User.find(:first, :conditions => {:email => params[:username]})
      end
      if u and u.send_new_password
        flash[:notice]  = "A new password has been sent."
        redirect_to :controller => 'user', :action =>'login'
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username or email."
      end
    end
  end

  def change_password
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if params[:password].blank?
        flash[:error] = "Passwords cannot be empty."
        redirect_to :controller => 'user', :action => 'change_password'
      else
        @user.update_attributes(:password => params[:password], :password_confirmation => params[:password_confirmation])
        if @user.save
          flash[:notice] = "Password changed."
          redirect_to :controller => 'user', :action => 'account'
        else
          flash[:error] = "Password not changed. Passwords must be at least 3 characters and match the confirmation field."
          redirect_to :controller => 'user', :action => 'change_password'
        end
      end
    end
  end
  
  def change_email
    @user = User.find_by_id(@current_user.id)
    if request.post?
      if @user.update_email(params[:email])
        flash[:notice]  = "Your email has been updated."
        redirect_to :controller => 'user', :action => 'logout'
      else
        flash.now[:error]  = "Could not update email. Please try again."
      end
    end
  end
  
  def activate
    if params[:activation_code].blank? or params[:user_id].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller => 'user', :action => :reactivate
    else      
      activation_code = params[:activation_code] 
      user = User.find(:first, :conditions => {:id => params[:user_id]})
      if user && user.active && activation_code == user.activation_code
        # Activate the user
        user.activate
        flash[:notice] = "Congratulations! Your account is now active. Please login."
        redirect_to :controller => 'user', :action => :login
      else 
        flash[:error]  = "Invalid activation code. Maybe you've already activated. Try signing in."
        redirect_to :controller => 'user', :action => :login
      end
    end
  end
  
  def reactivate
    if request.post?
      u = User.find(:first, :conditions => {:username => params[:username]})
      if u.nil?
        u = User.find(:first, :conditions => {:email => params[:username]})
      end
      if u and u.send_activation
        flash[:notice]  = "An activation code has been sent by email."
        redirect_to :controller => 'user', :action =>'login'
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username and email."
      end
    end    
  end
  
end