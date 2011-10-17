require "exception"
require "fastercsv"

class MerchantController < ApplicationController
  before_filter :require_merchant, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :connect, :connect_success]
  before_filter :require_terms, :except => [:signup, :forgot_password, :activate, :reactivate, :login, :logout, :connect, :connect_success, :accept_terms]

  ssl_required :login, :signup, :account, :change_password, :change_email, :connect
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
    if @current_merchant.merchant_subdomain
      @deal_store_url = new_host_subdomain(request.host_with_port, request.subdomain, @current_merchant.merchant_subdomain.subdomain)
    end
  end

  def new_deal
    unless @deal
      @deal = Deal.new()
      
      # Set some deafults
      @deal.start_date = Time.zone.today
      @deal.end_date = Time.zone.today + 1.weeks
      @deal.expiration_date = Time.zone.today + 2.months
    end
  end

  def create_deal
    @deal = Deal.new(:merchant_id => @current_merchant.id, :title => params[:title],
    :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
    :deal_price => params[:deal_price], :deal_value => params[:deal_value], 
    :min => params[:min], :max => params[:max], :limit => params[:limit],
    :description => params[:description], :terms => params[:terms])
    
    begin
      Deal.transaction do
        # Create Deal
        @deal.save!
        # Create each new DealImage
        if (image = params[:image1])
            di = DealImage.new(:deal_id => @deal.id, :counter => 1, :image => image)
            di.save!
        end
        if (image = params[:image2])
            di = DealImage.new(:deal_id => @deal.id, :counter => 2, :image => image)
            di.save!
        end
        if (image = params[:image3])
            di = DealImage.new(:deal_id => @deal.id, :counter => 3, :image => image)
            di.save!
        end
        if (video = params[:video])
            dv = DealVideo.new(:deal_id => @deal.id, :counter => 1, :video => video)
            dv.save!
        end
        if (file = params[:codes_file])
          FasterCSV.foreach(file.path) do |row|
            dc = DealCode.new(:deal_id => @deal.id, :code => row[0])
            dc.save!
          end
        end 
        if (!params[:incentive_type].blank?)
          di = DealIncentive.new(:deal_id => @deal.id, :metric_type => params[:incentive_type], 
            :incentive_price => params[:deal_price], :incentive_value => params[:incentive_value], 
            :number_required => params[:incentive_required], :max => params[:incentive_max])
          di.save!
          if (file = params[:incentive_codes_file])
            FasterCSV.foreach(file.path) do |row|
              dc = DealIncentiveCode.new(:deal_incentive_id => di.id, :code => row[0])
              dc.save!
            end
          end
        end     
      end
      flash[:notice] = "Your deal was created successfully."
      redirect_to :controller => self.controller_name, :action => :deals
      return
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error(invalid.record.errors)
      flash.now[:error] = "#{pp_errors(invalid.record.errors)}"
      render :new_deal
      return
    end    
  end
  
  def edit_deal
    unless @deal
      @deal = Deal.find_by_id(params[:id])
    end

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
    @video = @deal.deal_video ? @deal.deal_video : nil
    
    @num_deal_codes = DealCode.count(:conditions => "deal_id = #{@deal.id}")
    if @deal.deal_incentive
      @num_incentive_codes = DealIncentiveCode.count(:conditions => "deal_incentive_id = #{@deal.deal_incentive.id}")
    end
  end
  
  def update_deal
    @deal = Deal.find_by_id(params[:id])
    
    unless @deal.merchant == @current_merchant
      go_home
      return
    end
    
    begin
      Deal.transaction do
        # Update Deal
        if @deal.published
          @deal.update_attributes!(:merchant_id => @current_merchant.id, :title => params[:title],
          :start_date => params[:start_date], :end_date => params[:end_date],
          :description => params[:description], :terms => params[:terms])
        else
          @deal.update_attributes!(:merchant_id => @current_merchant.id, :title => params[:title],
          :start_date => params[:start_date], :end_date => params[:end_date], :expiration_date => params[:expiration_date],
          :deal_price => params[:deal_price], :deal_value => params[:deal_value], 
          :min => params[:min], :max => params[:max], :limit => params[:limit],
          :description => params[:description], :terms => params[:terms])
        end
        # Create each new DealImage
        if (image = params[:image1])
          DealImage.delete_all(["deal_id = ? AND counter = 1", @deal.id])
          di = DealImage.new(:deal_id => @deal.id, :counter => 1, :image => image)
          di.save!
        end
        if (image = params[:image2])
          DealImage.delete_all(["deal_id = ? AND counter = 2", @deal.id])
          di = DealImage.new(:deal_id => @deal.id, :counter => 2, :image => image)
          di.save!
        end
        if (image = params[:image3])
          DealImage.delete_all(["deal_id = ? AND counter = 3", @deal.id])
          di = DealImage.new(:deal_id => @deal.id, :counter => 3, :image => image)
          di.save!
        end
        if (video = params[:video])
          DealVideo.delete_all(["deal_id = ? AND counter = 1", @deal.id])
          dv = DealVideo.new(:deal_id => @deal.id, :counter => 1, :video => video)
          dv.save!
        end       
        if (file = params[:codes_file] and !@deal.published)
          DealCode.delete_all(["deal_id = ?", @deal.id])
          FasterCSV.foreach(file.path) do |row|
            dc = DealCode.new(:deal_id => @deal.id, :code => row[0])
            dc.save!
          end
        end
        DealIncentive.delete_all(["deal_id = ?", @deal.id])
        if (!params[:incentive_type].blank? and !@deal.published)
          di = DealIncentive.new(:deal_id => @deal.id, :metric_type => params[:incentive_type], 
            :incentive_price => params[:deal_price], :incentive_value => params[:incentive_value], 
            :number_required => params[:incentive_required], :max => params[:incentive_max])
          di.save!
          if (file = params[:incentive_codes_file])
            DealIncentiveCode.delete_all(["deal_incentive_id = ?", di.id])
            FasterCSV.foreach(file.path) do |row|
              dc = DealIncentiveCode.new(:deal_incentive_id => di.id, :code => row[0])
              dc.save!
            end
          end
        end
      end
      flash[:notice] = "Your deal was updated successfully."
      if @deal.published 
        selector = 'current'
      else
        selector = 'drafts'
      end
      redirect_to :controller => self.controller_name, :action => :deals, :selector => selector
      return
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error(invalid.record.errors)
      flash.now[:error] = "#{pp_errors(invalid.record.errors)}"
      render :edit_deal
    end        
  end

  def publish_deal
    deal = Deal.find_by_id(params[:id])
    
    unless deal.merchant == @current_merchant
      go_home
      return
    end
    
    if deal.deal_codes.size == 0
      flash[:error] = "You must upload coupon codes before you can publish."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
      return
    end
    
    if deal.deal_images.size == 0
      flash[:error] = "You must upload at least one image before you can publish."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
      return
    end
    
    if deal.deal_incentive
      if deal.deal_incentive.deal_incentive_codes.size == 0
        flash[:error] = "You must upload coupon codes for your deal incentive before you can publish."
        redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
        return        
      end
      if deal.deal_incentive.incentive_value < deal.deal_value
        flash[:error] = "The incentive value must be greater than or equal to the deal value."
        redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
        return
      end
    end
    
    if deal.publish
      flash[:notice] = "Your deal was published successfully."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'current'
      return
    else
      flash[:error] = "There was a problem publishing your deal. Please try again."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
      return
    end        
  end

  def delete_deal
    deal = Deal.find_by_id(params[:id])
    
    unless deal.merchant == @current_merchant
      go_home
      return
    end
    
    if deal.delete
      flash[:notice] = "Your draft was deleted."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
      return
    else
      flash[:error] = "There was a problem publishing your deal. Please try again."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'drafts'
      return
    end
  end
  
  def tip_deal
    deal = Deal.find_by_id(params[:id])

    unless deal.merchant == @current_merchant
      go_home
      return
    end

    if deal.force_tip
      flash[:notice] = "Your deal is tipped."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'success'
      return
    else
      flash[:error] = "There was a problem tipping your deal. Please try again."
      redirect_to :controller => self.controller_name, :action => :deals, :selector => 'failure'
      return
    end
  end
  
  # Home
  def home
    if request.post?
      # verify date format and conditions
      if verify_date(params[:start_date]) && verify_date(params[:end_date])
        start_date = Time.zone.parse(params[:start_date]).to_date
        end_date = Time.zone.parse(params[:end_date]).to_date

        if start_date > end_date
          flash[:error] = "Start Day cannot be after End Day."
          redirect_to :controller => self.controller_name, :action => :home
          return
        end
        if end_date - start_date > 365
          flash[:error] = "Date range cannot be greater than 1 year."
          redirect_to :controller => self.controller_name, :action => :home
          return
        end
        # set new dates
        session[:start_date] = start_date
        session[:end_date] = end_date
      else
        flash[:error] = "Dates must be of the form: MM/DD/YY"
        redirect_to :controller => self.controller_name, :action => :home
        return
      end

    end
    
    # use default dates, if not set
    @start_date = session[:start_date] ? session[:start_date] : Time.zone.today - 6.days
    @end_date = session[:end_date] ? session[:end_date] : Time.zone.today
    
    @deals = @current_merchant.deals_in_date_range(@start_date.beginning_of_day, @end_date.end_of_day)
  end
  
  # Account methods
  def account
    @merchant = Merchant.find_by_id(@current_merchant.id)
    if @merchant.merchant_subdomain
      @deal_store_url = new_host_subdomain(request.host_with_port, request.subdomain, @merchant.merchant_subdomain.subdomain)
    end
    @base_host = base_host(request.host_with_port, request.subdomain)
    
    if request.put?
      # set subdomain to nil if empty
      subdomain = (params[:merchant][:subdomain] and params[:merchant][:subdomain].empty?) ? nil : params[:merchant][:subdomain]
      params[:merchant].delete(:subdomain)
      
      # Can't update time zone
      params[:merchant].delete(:time_zone)
      
      # Check for available subdomain
      if merchant_subdomain = MerchantSubdomain.find_by_subdomain(subdomain) and merchant_subdomain.merchant_id != @merchant.id
        flash.now[:error] = "Subdomain \"#{subdomain}\" is already taken. Please choose another."
        render(:action => :account)
        return
      end
      
      begin
        Merchant.transaction do
          @merchant.update_attributes!(params[:merchant])
          if subdomain
            if merchant_subdomain = MerchantSubdomain.find_by_merchant_id(@merchant.id)
              merchant_subdomain.update_attributes!(:subdomain => subdomain)
            else
              MerchantSubdomain.create!(:merchant_id => @merchant.id, :subdomain => subdomain)
            end
          end
        end
      rescue ActiveRecord::RecordInvalid => invalid
        logger.error "Merchant.account: Couldn't update Merchant #{@merchant} #{invalid}"
        flash.now[:error] = "#{pp_errors(invalid.record.errors)}"
        return      
      end
      flash[:notice] = "Your account has been updated."
      redirect_to :controller => self.controller_name, :action => :account
      return
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
        logger.error "Merchant.signup: Couldn't create Merchant #{@merchant} #{invalid}"
        flash.now[:error] = "Signup unsuccessful. Please try again."
        render(:action => :signup)
        return
      rescue EmailError => e
        logger.error "Merchant.signup: Couldn't send activation email for Merchant#{@merchant} #{e}"   
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
  
  def accept_terms
    if request.post?
      if params[:terms]
        if @current_merchant.update_attributes(:terms => true)
          go_home
          return
        else
          logger.error "Merchant.tos: Couldn't update tos for Merchant #{@merchant}"
          flash.now[:error]  = "Could not update your account. Please try again."
        end
      else 
        flash.now[:error] = "You must agree to the Terms and Conditions."
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
        flash[:error] = "Unable to access Facebook for information on your page. Please try again."
        redirect_to :controller => self.controller_name, :action => :home, :fb_page_id => nil
        return
      end
    else
      flash[:error] = "Unable to access Facebook for information on your page. Please try again."
      redirect_to :controller => self.controller_name, :action => :home, :fb_page_id => nil
      return
    end
    
    # Already connected?
    if Merchant.find_by_facebook_page_id(@fb_page_id)
      redirect_to :controller => self.controller_name, :action => :connect_success, :fb_page_id => params[:fb_page_id]
      return
    end
    
    if request.post?
      m = Merchant.authenticate(params[:username], params[:password])
      if m.nil?
        flash.now[:error] = "Login unsuccessful."
      else
        if m.active
          if m.activated
            if m.update_attributes(:facebook_page_id => @fb_page_id)
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
        flash[:error] = "Unable to access Facebook for information on your page. Please try again."
        redirect_to :controller => self.controller_name, :action => :home, :fb_page_id => nil
        return
      end
    else
      flash[:error] = "Unable to access Facebook for information on your page. Please try again."
      redirect_to :controller => self.controller_name, :action => :home, :fb_page_id => nil
      return
    end
    render :layout => "facebook_merchant"
  end

end