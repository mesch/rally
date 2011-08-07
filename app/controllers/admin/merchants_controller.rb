require 'subdomain'

class Admin::MerchantsController < AdminController

  def index
    @merchants = Merchant.search(params[:search], params[:page])
  end
  
  def show
    @merchant = Merchant.find_by_id(params[:id])
  end
  
  def edit
    @merchant = Merchant.find_by_id(params[:id])
    if @merchant.merchant_subdomain
      @deal_store_url = new_host_subdomain(request, @merchant.merchant_subdomain.subdomain)
    end
    @base_host = base_host(request)
  end
  
  def update
    @merchant = Merchant.find_by_id(params[:id])

    # set subdomain to nil if empty
    subdomain = (params[:merchant][:subdomain] and params[:merchant][:subdomain].empty?) ? nil : params[:merchant][:subdomain]
    params[:merchant].delete(:subdomain)
        
    # Check for available subdomain
    if merchant_subdomain = MerchantSubdomain.find_by_subdomain(subdomain) and merchant_subdomain.merchant_id != @merchant.id
      flash.now[:error] = "Subdomain \"#{subdomain}\" is already taken. Please choose another."
      render(:action => :edit)
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
      logger.error "AdminMerchants.edit: Couldn't update Merchant #{@merchant}", invalid
      flash.now[:error] = "#{pp_errors(@merchant.errors)}"
      render(:action => :edit)
      return        
    end
    flash.now[:notice] = "Account updated."
    redirect_to :controller => self.controller_name, :action => :index
    return
  end  
  
  def new
    unless @merchant
      @merchant = Merchant.new()
      if @merchant.merchant_subdomain
        @deal_store_url = new_host_subdomain(request, @merchant.merchant_subdomain.subdomain)
      end
      @base_host = base_host(request)
    end
  end

  def create
    # set subdomain to nil if empty
    subdomain = (params[:merchant][:subdomain] and params[:merchant][:subdomain].empty?) ? nil : params[:merchant][:subdomain]
    params[:merchant].delete(:subdomain)
    
    @merchant = Merchant.new(params[:merchant])
    
    # Check for available subdomain
    if merchant_subdomain = MerchantSubdomain.find_by_subdomain(subdomain) and merchant_subdomain.merchant_id != @merchant.id
      flash.now[:error] = "Subdomain \"#{subdomain}\" is already taken. Please choose another."
      render(:action => :new)
      return
    end
    
    begin       
      Merchant.transaction do
        @merchant.save!
        if subdomain
          merchant_subdomain = MerchantSubdomain.create!(:merchant_id => @merchant.id, :subdomain => subdomain)
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      logger.error "AdminMerchants.create: Couldn't create Merchant #{@merchant}", invalid
      flash.now[:error] = "#{pp_errors(invalid.record.errors)}"
      render(:action => :new)
      return  
    end
    
    flash[:notice] = "Account created."
    redirect_to :controller => self.controller_name, :action => :index
    return
  end
  
  def change_password
    @merchant = Merchant.find_by_id(params[:id])
    if request.post?
      if params[:password].blank?
        flash[:error] = "Passwords cannot be empty."
        redirect_to :controller => self.controller_name, :action => :change_password
        return
      else
        @merchant.update_attributes(:password => params[:password], :password_confirmation => params[:password_confirmation])
        if @merchant.save
          flash[:notice] = "Password changed."
          redirect_to :controller => self.controller_name, :action => :edit, :id => params[:id]
          return
        else
          logger.error "AdminMerchants.change_password: Couldn't update password for Merchant #{@merchant}"
          flash[:error] = "#{pp_errors(@merchant.errors)}"
          redirect_to :controller => self.controller_name, :action => 'change_password', :id => params[:id]
          return
        end
      end
    end
  end
  
  def change_email
    @merchant = Merchant.find_by_id(params[:id])
    if request.post?
      if @merchant.update_attributes(:email => params[:email])
        flash[:notice] = "Email has been updated."
        redirect_to :controller => self.controller_name, :action => :edit, :id => params[:id]
        return
      else
        logger.error "AdminMerchants.change_email: Couldn't update email for Merchant #{@merchant}"
        flash.now[:error]  = "#{pp_errors(@merchant.errors)}"
        redirect_to :controller => self.controller_name, :action => 'change_email', :id => params[:id]
      end
    end
  end
  
  def send_activation
    @merchant = Merchant.find_by_id(params[:id])
    if @merchant.send_activation
      flash[:notice] = "Activation email has been sent."
      redirect_to :controller => self.controller_name, :action => :edit, :id => params[:id]
      return
    else
      logger.error "AdminMerchants.send_activation: Couldn't send activation email for Merchant #{@merchant}"
      flash.now[:error] = "Couldn't send activation email. Try again."
      redirect_to :controller => self.controller_name, :action => :edit, :id => params[:id]
      return
    end
  end
  
  def impersonate
    @merchant = Merchant.find_by_id(params[:id])
    session[:merchant_id] = @merchant.id
    redirect_to :controller => "/merchant", :action => 'home'
  end

end