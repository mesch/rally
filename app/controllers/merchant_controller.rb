class MerchantController < ApplicationController
  before_filter :require_merchant, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout]
  
  # Use the merchant layout
  layout "merchant"

  # Deals
  def deals
    @deals = Deal.find(:all, 
      :conditions => {:merchant_id => @current_merchant.id }, 
      :order => 'active desc, created_at desc')
  end

  def new_deal
    @deal = Deal.new()
    
    # Set some deafults
    @deal.start_date = Time.zone.today
    @deal.end_date = Time.zone.today + 1.months
    @deal.expiration_date = Time.zone.today + 2.months
    
    render :deal_form
  end

  def create_deal
    begin
      Deal.transaction do
        # Create Badge
        deal = Deal.new(:merchant_id => @current_merchant.id, :title => params[:title],
        :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
        :deal_price => params[:deal_price], :deal_value => params[:deal_value], :max => params[:max], :limit => params[:limit],
        :description => params[:description], :terms => params[:terms], :video => params[:video])
        deal.save!
        # Create each new DealImage
        if (image = params[:image1])
            di = DealImage.new(:deal_id => deal.id, :counter => 1, :image => image)
            di.save!
        end
        if (image = params[:image2])
            di = DealImage.new(:deal_id => deal.id, :counter => 2, :image => image)
            di.save!
        end
        if (image = params[:image3])
            di = DealImage.new(:deal_id => deal.id, :counter => 3, :image => image)
            di.save!
        end 
        if (file = params[:codes_file])
          while (line = file.gets)
            dc = DealCode.new(:deal_id => deal.id, :code => line.strip)
            dc.save!
          end
        end       
      end
      flash[:notice] = "Your deal was created successfully."
      redirect_to :controller => 'merchant', :action => :deals
    rescue ActiveRecord::RecordInvalid => invalid
      ### TODO: add invalid.record.errors?
      p invalid.record.errors
      flash[:error] = "There was a problem creating your deal."
      redirect_to :controller => 'merchant', :action => :new_deal
    end    
  end
  
  def edit_deal
    @deal = Deal.find(params[:id])
    deal_images = DealImage.find(:all, 
      :conditions => { :deal_id => @deal.id }, 
      :order => 'created_at asc')
    @image1 = deal_images[0] ? @deal.deal_images[0] : nil
    @image2 = deal_images[1] ? @deal.deal_images[1] : nil
    @image3 = deal_images[2] ? @deal.deal_images[2] : nil
    
    @num_deal_codes = DealCode.count(:conditions => "deal_id = #{@deal.id}")
    
    render :deal_form
  end
  
  def update_deal
    deal = Deal.find(params[:id])
    begin
      Deal.transaction do
        # Update deal
        deal.update_attributes!(:merchant_id => @current_merchant.id, :title => params[:title],
        :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
        :deal_price => params[:deal_price], :deal_value => params[:deal_value], :max => params[:max], :limit => params[:limit],
        :description => params[:description], :terms => params[:terms], :video => params[:video])
        # Create each new DealImage
        if (image = params[:image1])
          DealImage.delete_all(:conditions => { :deal_id => deal.id, :counter => 1 })
          di = DealImage.new(:deal_id => deal.id, :counter => 1, :image => image)
          di.save!
        end
        if (image = params[:image2])
          DealImage.delete_all(:conditions => { :deal_id => deal.id, :counter => 2 })
          di = DealImage.new(:deal_id => deal.id, :counter => 2, :image => image)
          di.save!
        end
        if (image = params[:image3])
          DealImage.delete_all(:conditions => { :deal_id => deal.id, :counter => 3})
          di = DealImage.new(:deal_id => deal.id, :counter => 3, :image => image)
          di.save!
        end
        if (file = params[:codes_file])
          DealCode.delete_all(:deal_id => deal.id)
          while (line = file.gets)
            dc = DealCode.new(:deal_id => deal.id, :code => line.strip)
            dc.save!
          end
        end
      end
      flash[:notice] = "Your deal was updated successfully."
      redirect_to :controller => 'merchant', :action => :deals
    rescue ActiveRecord::RecordInvalid => invalid
      ### TODO: add invalid.record.errors?
      flash[:error] = "There was a problem updating your deal."
      redirect_to :controller => 'merchant', :action => :edit_deal
    end        
  end

  # Home
  def home

  end
  
  # Account methods
  def account
    @merchant = Merchant.find(@current_merchant.id)
    if request.post?
      if @merchant.update_attributes(:name => params[:name], :website => params[:website], 
        :contact_name => params[:contact_name], :address1 => params[:address1], :address2 => params[:address2], 
        :city => params[:city], :state => params[:state], :zip => params[:zip], :country => params[:country],
        :phone_number => params[:phone_number], :tax_id => params[:tax_id], :bank => params[:bank], 
        :account_name => params[:account_name], :routing_number => params[:routing_number], 
        :account_number => params[:account_number], :paypal_account => params[:paypal_account])
        flash.now[:notice] = "Your account has been updated."
      else
        flash.now[:error] = "Could not update account. Please try again."
      end
    end
  end

  def signup    
    unless @merchant
      @merchant = Merchant.new()
    end
    if request.post?
      @merchant = Merchant.new(:name => params[:name], :username => params[:username], 
        :password => params[:password], :password_confirmation => params[:password_confirmation],
        :email => params[:email], :time_zone => params[:time_zone], :website => params[:website], 
        :contact_name => params[:contact_name], :address1 => params[:address1], :address2 => params[:address2], 
        :city => params[:city], :state => params[:state], :zip => params[:zip], :country => params[:country],
        :phone_number => params[:phone_number], :tax_id => params[:tax_id], :bank => params[:bank], 
        :account_name => params[:account_name], :routing_number => params[:routing_number], 
        :account_number => params[:account_number], :paypal_account => params[:paypal_account])
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
      if @merchant.save and @merchant.send_activation()
          flash[:notice] = "Signup successful. An activation code has been sent."
          redirect_to :controller => 'merchant', :action =>'login'
      else
        p @merchant
        p @merchant.save
        p @merchant.send_activation()
        flash.now[:error] = "Signup unsuccessful."
        render(:action => :signup)
      end
    end
  end

  def login
    @merchant = Merchant.new()
    if request.post?
      m = Merchant.authenticate(params[:username], params[:password])
      if m.nil?
        flash.now[:error] = "Login unsuccessful."
      else
        if m.active
          if m.activated
            session[:merchant_id] = m.id
            redirect_to_stored
          else
            flash[:error] = "You must activate your account."
            redirect_to :controller => 'merchant', :action => :reactivate
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
    redirect_to :controller => 'merchant', :action => 'login'
  end

  def forgot_password
    if request.post?
      c = Merchant.find(:first, :conditions => {:username => params[:username], :email => params[:email]})
      if c and c.send_new_password
        flash[:notice]  = "A new password has been sent."
        redirect_to :controller => 'merchant', :action =>'login'
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username and email."
      end
    end
  end

  def change_password
    @merchant = Merchant.find(@current_merchant.id)
    if request.post?
      if params[:password].blank?
        flash[:error] = "Passwords cannot be empty."
        redirect_to :controller => 'merchant', :action => 'change_password'
      else
        @merchant.update_attributes(:password => params[:password], :password_confirmation => params[:password_confirmation])
        if @merchant.save
          flash[:notice] = "Password changed."
          redirect_to :controller => 'merchant', :action => 'account'
        else
          flash[:error] = "Password not changed. Passwords must be at least 3 characters and match the confirmation field."
          redirect_to :controller => 'merchant', :action => 'change_password'
        end
      end
    end
  end
  
  def change_email
    @merchant = Merchant.find(@current_merchant.id)
    if request.post?
      if @merchant.update_email(params[:email])
        flash[:notice]  = "Your email has been updated."
        redirect_to :controller => 'merchant', :action => 'logout'
      else
        flash.now[:error]  = "Could not update email. Please try again."
      end
    end
  end
  
  def activate
    if params[:activation_code].blank? or params[:merchant_id].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller => 'merchant', :action => :reactivate
    else      
      activation_code = params[:activation_code] 
      merchant = Merchant.find(:first, :conditions => {:id => params[:merchant_id]})
      if merchant && merchant.active && activation_code == merchant.activation_code
        # Activate the merchant
        merchant.activate
        flash[:notice] = "Congratulations! Your account is now active. Please login."
        redirect_to :controller => 'merchant', :action => :login
      else 
        flash[:error]  = "Invalid activation code. Maybe you've already activated. Try signing in."
        redirect_to :controller => 'merchant', :action => :login
      end
    end
  end
  
  def reactivate
    if request.post?
      m = Merchant.find(:first, :conditions => {:username => params[:username], :email => params[:email]})
      if m and m.send_activation
        flash[:notice]  = "An activation code has been sent by email."
        redirect_to :controller => 'merchant', :action =>'login'
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username and email."
      end
    end    
  end

end