require "exception"

class MerchantController < ApplicationController
  before_filter :require_merchant, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :connect, :connect_success]

  ssl_required :login, :signup, :account, :change_password, :change_email
  ssl_allowed :home
  
  # Use the merchant layout
  layout "merchant"

  def go_home
    redirect_to :controller => self.controller_name, :action => 'home'
  end

  # Deals
  def deals
    @selector = params[:selector] ? params[:selector] : 'drafts'
    if @selector == 'current'
      @deals = @current_merchant.current_deals
    elsif @selector == 'success'
      @deals = @current_merchant.good_deals
    elsif @selector == 'failure'
      @deals = @current_merchant.failed_deals
    else
      @deals = @current_merchant.drafts
    end
  end

  def new_deal
    @deal = Deal.new()
    
    # Set some deafults
    @deal.start_date = Time.zone.today
    @deal.end_date = Time.zone.today + 1.weeks
    @deal.expiration_date = Time.zone.today + 2.months
    
    render :deal_form
  end

  def create_deal
    begin
      Deal.transaction do
        # Create Badge
        deal = Deal.new(:merchant_id => @current_merchant.id, :title => params[:title],
        :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
        :deal_price => params[:deal_price], :deal_value => params[:deal_value], 
        :min => params[:min], :max => params[:max], :limit => params[:limit],
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
      redirect_to :controller => self.controller_name, :action => :deals
      return
    rescue ActiveRecord::RecordInvalid => invalid
      ### TODO: add invalid.record.errors?
      flash[:error] = "There was a problem creating your deal."
      redirect_to :controller => self.controller_name, :action => :new_deal
      return
    end    
  end
  
  def edit_deal
    @deal = Deal.find_by_id(params[:id])

    unless @deal.merchant == @current_merchant
      go_home
      return
    end
    
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
    deal = Deal.find_by_id(params[:id])
    
    unless deal.merchant == @current_merchant
      go_home
      return
    end
    
    begin
      Deal.transaction do
        # Update deal
        if deal.published
          deal.update_attributes!(:merchant_id => @current_merchant.id, :title => params[:title],
          :start_date => params[:start_date], :end_date => params[:end_date],
          :description => params[:description], :terms => params[:terms], :video => params[:video])
        else
          deal.update_attributes!(:merchant_id => @current_merchant.id, :title => params[:title],
          :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
          :deal_price => params[:deal_price], :deal_value => params[:deal_value], 
          :min => params[:min], :max => params[:max], :limit => params[:limit],
          :description => params[:description], :terms => params[:terms], :video => params[:video])
        end
        # Create each new DealImage
        if (image = params[:image1])
          DealImage.delete_all(["deal_id = ? AND counter = 1", deal.id])
          di = DealImage.new(:deal_id => deal.id, :counter => 1, :image => image)
          di.save!
        end
        if (image = params[:image2])
          DealImage.delete_all(["deal_id = ? AND counter = 2", deal.id])
          di = DealImage.new(:deal_id => deal.id, :counter => 2, :image => image)
          di.save!
        end
        if (image = params[:image3])
          DealImage.delete_all(["deal_id = ? AND counter = 3", deal.id])
          di = DealImage.new(:deal_id => deal.id, :counter => 3, :image => image)
          di.save!
        end
        if (file = params[:codes_file] and !deal.published)
          DealCode.delete_all(["deal_id = ?", deal.id])
          while (line = file.gets)
            dc = DealCode.new(:deal_id => deal.id, :code => line.strip)
            dc.save!
          end
        end
      end
      flash[:notice] = "Your deal was updated successfully."
      if deal.published 
        selector = 'current'
      else
        selector = 'drafts'
      end
      redirect_to :controller => self.controller_name, :action => :deals, :selector => selector
      return
    rescue ActiveRecord::RecordInvalid => invalid
      ### TODO: add invalid.record.errors?
      flash[:error] = "There was a problem updating your deal."
      redirect_to :controller => self.controller_name, :action => :edit_deal
      return
    end        
  end

  def publish_deal
    deal = Deal.find_by_id(params[:id])
    
    unless deal.merchant == @current_merchant
      go_home
      return
    end
    
    if deal.publish
      flash[:notice] = "Your deal was published successfully."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'current'
      return
    else
      flash[:error] = "There was a problem publishing your deal."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'current'
      return
    end        
  end

  # Home
  def home
    use_default = false
    if request.post?
      if verify_date(params[:start_day]) && verify_date(params[:end_day])
        start_date = Time.zone.parse(params[:start_day]).to_date
        end_date = Time.zone.parse(params[:end_day]).to_date

        if start_date > end_date
          use_default = true
          flash.now[:warning] = "Start Day cannot be after End Day."
        end
        if end_date - start_date + 1 > 365
          use_default = true
          flash.now[:warning] = "Date range cannot be greater than 1 year."
        end
      else
        use_default = true
        flash.now[:error] = "Dates must be of the form: MM/DD/YY"
      end
    else # request.get
      use_default = true
    end

    if use_default
      # default to last 7 days
      start_date = 0.days.ago.to_date - 6.days
      end_date = 0.days.ago.to_date
    end
    
    @num_days = end_date - start_date + 1
 
    @deals = @current_merchant.deals_in_date_range(start_date, end_date)
  
    @start_date = start_date
    @end_date = end_date.end_of_day
    @start_day = @start_date.strftime(OPTIONS[:date_format])
    @end_day = @end_date.strftime(OPTIONS[:date_format])

  end
  
  # Account methods
  def account
    @merchant = Merchant.find_by_id(@current_merchant.id)
    if request.post?
      # set subdomain to nil if empty
      subdomain = (params[:subdomain] and params[:subdomain].empty?) ? nil : params[:subdomain]
      
      # Check for available subdomain
      if merchant_subdomain = MerchantSubdomain.find_by_subdomain(subdomain) and merchant_subdomain.merchant_id != @merchant.id
        flash.now[:error] = "Subdomain \"#{subdomain}\" is already taken. Please choose another."
        render(:action => :account)
        return
      end
      
      begin
        Merchant.transaction do
          @merchant.update_attributes!(:name => params[:name], :website => params[:website], 
            :contact_name => params[:contact_name], :address1 => params[:address1], :address2 => params[:address2], 
            :city => params[:city], :state => params[:state], :zip => params[:zip], :country => params[:country],
            :phone_number => params[:phone_number], :tax_id => params[:tax_id], :bank => params[:bank], 
            :account_name => params[:account_name], :routing_number => params[:routing_number], 
            :account_number => params[:account_number], :paypal_account => params[:paypal_account])
          if params[:logo_file]
            @merchant.update_attributes!(:logo => params[:logo_file])
          end
          if subdomain
            if merchant_subdomain = MerchantSubdomain.find_by_merchant_id(@merchant.id)
              merchant_subdomain.update_attributes!(:subdomain => subdomain)
            else
              MerchantSubdomain.create!(:merchant_id => @merchant.id, :subdomain => params[:subdomain])
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => invalid
        logger.error "Merchant.account: Couldn't update Merchant #{@merchant}", invalid
        flash.now[:error] = "Could not update account. Please try again."
        return        
      end
      flash.now[:notice] = "Your account has been updated."
    end
  end

  def signup    
    unless @merchant
      @merchant = Merchant.new()
    end
    if request.post?
      # set subdomain to nil if empty
      subdomain = (params[:subdomain] and params[:subdomain].empty?) ? nil : params[:subdomain]

      @merchant = Merchant.new(:name => params[:name], :username => params[:username], 
        :password => params[:password], :password_confirmation => params[:password_confirmation],
        :email => params[:email], :time_zone => params[:time_zone], :logo => params[:logo_file], :website => params[:website], 
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
      # Captcha validation (allowing an out for test environment)
      unless Rails.env.test?
        unless verify_recaptcha(:private_key => OPTIONS[:recaptcha_private_key])      
          flash.now[:error] = "Invalid captcha results. Please try again."
          render(:action => :signup)
          return
        end
      end
      # Check for available subdomain
      if MerchantSubdomain.find_by_subdomain(subdomain)
        flash.now[:error] = "Subdomain \"#{subdomain}\" is already taken. Please choose another."
        render(:action => :signup)
        return
      end      

      begin       
        Merchant.transaction do
          @merchant.save!
          if subdomain
            merchant_subdomain = MerchantSubdomain.create!(:merchant_id => @merchant.id, :subdomain => params[:subdomain])
          end
          unless @merchant.send_activation()
            raise EmailError
          end
        end
      rescue ActiveRecord::RecordInvalid => invalid
        logger.error "Merchant.signup: Couldn't create Merchant #{@merchant}", invalid
        flash.now[:error] = "Signup unsuccessful. Please try again."
        render(:action => :signup)
        return
      rescue EmailError => e
        logger.error "Merchant.signup: Couldn't send activation email for Merchant#{@merchant}", e    
      end
      
      flash[:notice] = "Signup successful. An activation code has been sent."
      redirect_to :controller => self.controller_name, :action => :login
      return
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
            redirect_merchant_to_stored
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
  end

  def logout
    @current_user = nil
    reset_session
    redirect_to :controller => self.controller_name, :action => :login
  end

  def forgot_password
    if request.post?
      u = Merchant.find(:first, :conditions => {:username => params[:username], :email => params[:email]})
      if u and u.send_new_password
        flash[:notice]  = "A new password has been sent."
        redirect_to :controller => self.controller_name, :action =>:login
        return
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username and email."
      end
    end
  end

  def change_password
    @merchant = Merchant.find_by_id(@current_merchant.id)
    if request.post?
      if params[:password].blank?
        flash[:error] = "Passwords cannot be empty."
        redirect_to :controller => self.controller_name, :action => :change_password
        return
      else
        @merchant.update_attributes(:password => params[:password], :password_confirmation => params[:password_confirmation])
        if @merchant.save
          flash[:notice] = "Password changed."
          redirect_to :controller => self.controller_name, :action => :account
          return
        else
          logger.error "Merchant.change_password: Couldn't update password for Merchant #{@merchant}"
          flash[:error] = "Password not changed. Passwords must be at least 3 characters and match the confirmation field."
          redirect_to :controller => self.controller_name, :action => 'change_password'
          return
        end
      end
    end
  end
  
  def change_email
    @merchant = Merchant.find_by_id(@current_merchant.id)
    if request.post?
      if @merchant.update_email(params[:email])
        flash[:notice]  = "Your email has been updated."
        redirect_to :controller => self.controller_name, :action => :logout
        return
      else
        logger.error "Merchant.change_email: Couldn't update email for Merchant #{@merchant}"
        flash.now[:error]  = "Could not update email. Please try again."
      end
    end
  end
  
  def activate
    if params[:activation_code].blank? or params[:merchant_id].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_to :controller => self.controller_name, :action => :reactivate
      return
    else      
      activation_code = params[:activation_code] 
      merchant = Merchant.find(:first, :conditions => {:id => params[:merchant_id]})
      if merchant && merchant.active && activation_code == merchant.activation_code
        # Activate the merchant
        merchant.activate
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
      m = Merchant.find(:first, :conditions => {:username => params[:username], :email => params[:email]})
      if m and m.send_activation
        flash[:notice]  = "An activation code has been sent by email."
        redirect_to :controller => self.controller_name, :action =>:login
        return
      else
        flash.now[:error]  = "Could not find your account. Please enter a valid username and email."
      end
    end    
  end
  
  def connect
    if @fb_page_id = params[:fb_page_id]
      fb_page = get_fb_object(@fb_page_id)
      if fb_page
        @page_name = fb_page["name"]
        @page_link = fb_page["link"]
      else
        redirect_to :controller => 'facebook', :action => :home, :fb_page_id => nil
        return
      end
    else
      redirect_to :controller => 'facebook', :action => :home, :fb_page_id => nil
      return
    end
    
    if request.post?
      m = Merchant.authenticate(params[:username], params[:password])
      if m.nil?
        flash.now[:error] = "Login unsuccessful."
      else
        if m.active
          if m.activated
            if m.update_attributes(:facebook_page_id => :facebook_page_id)
              redirect_to :controller => self.controller_name, :action => :connect_success, :fb_page_id => params[:fb_page_id]
              return
            else
              logger.error "Merchant.connect: Couldn't update facebook_page_id for Merchant #{m}"
              flash.now[:error]  = "Could not update your facebook page connection. Please try again."
            end
          else
            flash.now[:reactivate_error] = true
          end
        else
          flash.now[:error] = "Your account is no longer active. Please contact customer support."
        end
      end
    end
    render :layout => "facebook_merchant"
  end
  
  def connect_success
    if @fb_page_id = params[:fb_page_id]
      fb_page = get_fb_object(@fb_page_id)
      if fb_page
        @page_name = fb_page["name"]
        @page_link = fb_page["link"]
      else
        redirect_to :controller => 'facebook', :action => :home, :fb_page_id => nil
        return
      end
    else
      redirect_to :controller => 'facebook', :action => :home, :fb_page_id => nil
      return
    end
    render :layout => "facebook_merchant"
  end

end