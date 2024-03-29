class UserController < ApplicationController
  before_filter :require_user, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :connect, 
                                            :deals, :deal, :splash, :home, :create_share, :update_share]
  before_filter :check_for_user, :only => [:home, :deals, :deal, :create_share, :update_share]
  before_filter :check_for_visitor
  after_filter :log_user_action
  
  ssl_required :login, :signup, :account, :change_password, :change_email if Rails.env.production?
  ssl_allowed :home
  
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
  def deals()
    # TODO: Move this query into deal.rb? or user.rb?
    logger.info(Time.zone)
    logger.info(Time.zone.now)
    @deals = Deal.find(:all, :conditions => [ "published = ? AND start_date <= ? AND end_date >= ?", true, Time.zone.now, Time.zone.now])
    logger.info(@deals)
    
    # filter out other merchants if on a merchant subdomain
    if @merchant_subdomain and @merchant_subdomain.merchant
      @deals.delete_if {|deal| deal.merchant_id != @merchant_subdomain.merchant.id}
    end
    
    if @deals.size == 1
      redirect_to :controller => self.controller_name, :action => 'deal', :id => @deals[0].id
      return
    end
    render "user/#{self.action_name}"
  end
  
  def deal
    @deal = Deal.find_by_id(params[:id])
    unless @deal
      go_home
      return
    end
    
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
    logger.info(Time.zone)
    logger.info(Time.zone.now)
    @others = Deal.find(
      :all, 
      :conditions => [ "published = ? AND start_date <= ? AND end_date >= ? AND id != ?", true, Time.zone.now, Time.zone.now, @deal.id], 
      :limit => 3)
    logger.info(@others)
    # filter out other merchants if on a merchant subdomain
    if @merchant_subdomain and @merchant_subdomain.merchant
      @others.delete_if {|other| other.merchant_id != @merchant_subdomain.merchant.id}
    end
    
    @deal_url = generate_deal_url(@deal)
      
    render "user/#{self.action_name}"
  end

  # Coupons
  def coupons()
    @coupons = @current_user.coupons
    
    # filter out other merchants if on a merchant subdomain
    if @merchant_subdomain and @merchant_subdomain.merchant
      @coupons.delete_if {|coupon| coupon.deal.merchant_id != @merchant_subdomain.merchant.id}
    end

    render "user/#{self.action_name}"
  end
  
  def coupon
    @coupon = Coupon.find_by_id(params[:id])

    unless @coupon.user == @current_user
      go_home
      return
    end
    
    unless @coupon.state == 'Active' or @coupon.state == 'Expired'
      go_home
      return
    end
    
    render "user/#{self.action_name}", :layout => false
  end
  
=begin
  # Shares
  def create_share
    user_id = @current_user ? @current_user.id : nil
    share = Share.new(:deal_id => params[:deal_id], :user_id => user_id)
    if share.save
      return render :json => { :result => "success", :message => "Share created", :share_id => share.id, 
        :update_share_url => url_for(:controller => self.controller_name, :action => 'update_share', :id => share.id) }
    else
      return render :json => { :result => "error", :message => "Unable to create share" }
    end
  end
  
  def update_share
    share = Share.find_by_id(params[:id])
    if share and share.update_attributes(:post_id => params[:post_id], :posted => true)
      return render :json => { :result => "success", :message => "Share updated" }
    else
      return render :json => { :result => "error", :message => "Unable to update share" }
    end
  end
=end
  
  # Incentive Methods
  def share
    @deal = Deal.find_by_id(params[:deal_id])
    unless @deal and @deal.deal_incentive
      go_home
      return
    end
    
    render "user/#{self.action_name}"
  end

  # FB Methods
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
      # update facebook_id
      unless user and user.update_attributes(:facebook_id => fb["id"])
        logger.error "UserController.connect: Can't update facebook_id for User #{user}"
      end
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
    if params[:next_action]
      redirect_to :controller => self.controller_name, :action => params[:next_action], :deal_id => params[:deal_id]
    else
      redirect_user_to_stored
    end
  end
  
  def confirm_permissions
    @deal = Deal.find_by_id(params[:deal_id])
    unless @deal and @deal.deal_incentive
      go_home
      return
    end
    
    # check for permissions
    fb_permissions = get_fb_user_permissions
    if fb_permissions and fb_permissions['publish_stream']
      redirect_to :controller => self.controller_name, :action => 'fb_share', :deal_id => @deal.id
      return
    end
    
    message = "You need to log in to Facebook with the proper permissions to share with your friends and turn your <strong class=\"old\">#{@deal.deal_value.format(:no_cents)}</strong> into <strong class=\"discount\">#{@deal.deal_incentive.incentive_value.format(:no_cents)}</strong>!"
    flash.now[:notice] = "#{message}"

    @next_action = 'facebook_share'
    render "user/#{self.action_name}"
  end
  
  def fb_share    
    @deal = Deal.find_by_id(params[:deal_id])
    unless @deal and @deal.deal_incentive
      go_home
      return
    end
    
    # check for permissions - again
    fb_permissions = get_fb_user_permissions
    unless fb_permissions and fb_permissions['publish_stream']
      redirect_to :controller => self.controller_name, :action => 'confirm_permissions', :deal_id => @deal.id
      return
    end
    
    if request.post?
      facebook_ids = params[:facebook_ids]
      unless facebook_ids and facebook_ids.size >= @deal.deal_incentive.number_required
        flash[:error] = "You must select at least #{@deal.deal_incentive.number_required} friends."
        redirect_to :controller => self.controller_name, :action => 'fb_share', :deal_id => @deal.id
        return
      end
      
      for facebook_id in facebook_ids
        args = {:name => @deal.title,
          :link => url_for(:controller => self.controller_name, :action => 'deal', :id => @deal.id),
          :caption => @deal.merchant.name,
          :description => ActionController::Base.helpers.simple_format(ActionController::Base.helpers.strip_tags(@deal.description)),
          :picture => @deal.deal_images[0].image.url(:display)
        }
        put_wall_post(params[:message], args, facebook_id)

        share = Share.new(:user_id => @current_user.id, :deal_id => @deal.id, :facebook_id => facebook_id)
        unless share.save
          logger.error "User.fb_share: Couldn't create share #{share}: #{share.errors}"
        end
      end
      
      flash[:notice] = "Thank you sharing this deal."
      redirect_to :controller => self.controller_name, :action => 'deal', :id => @deal.id
      return
    end
    
    @facebook_profile_image = get_fb_picture(@current_user.facebook_id)
    @facebook_profile_url = get_fb_user["link"]
    @default_message = "Check out this great deal from #{@deal.merchant.name}!"
        
    render "user/#{self.action_name}"
  end
  
  # Account methods
  def home
    # just go to deals, for now?
    redirect_to :controller => self.controller_name, :action => 'deals'
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
        :password => params[:password], :password_confirmation => params[:password_confirmation], :terms => params[:terms])
      # Check TOS
      unless params[:terms]     
        flash.now[:error] = "You must agree to the Terms of Service."
        render "user/#{self.action_name}"
        return
      end
      # Captcha validation (allowing an out for test environment)
      unless Rails.env.test?
        unless verify_recaptcha(:private_key => OPTIONS[:recaptcha_private_key])      
          flash.now[:error] = "Invalid captcha results. Please try again."
          render "user/#{self.action_name}"
          return
        end
      end
      
      begin
        User.transaction do
          @user.save!
          @user.send_activation(request.host_with_port)
        end
      rescue ActiveRecord::RecordInvalid => invalid
        logger.error "User.signup: Couldn't update User #{@user.inspect}: #{invalid}"
        flash.now[:error] = "#{pp_errors(@user.errors)}"
        render "user/#{self.action_name}"
        return        
      end
      
      flash[:notice] = "Signup successful. An activation code has been sent."
      redirect_to :controller => self.controller_name, :action =>'login'
      return
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
      if u and u.send_new_password(request.host_with_port)
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
      if @user.update_email(request.host_with_port, params[:email])
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
      if u and u.send_activation(request.host_with_port)
        flash[:notice]  = "An activation code has been sent by email."
        redirect_to :controller => self.controller_name, :action =>'login'
        return
      else
        flash.now[:error] = "Could not find your account. Please enter a valid email."
        render "user/#{self.action_name}"
        return
      end
    end
  end
  
  private
  
  def generate_deal_url(deal)
    deal_url = url_for(:controller => self.controller_name, :action => 'deal', :id => deal.id)
    return deal_url
  end
  
end