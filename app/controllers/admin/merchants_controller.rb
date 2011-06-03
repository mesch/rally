class Admin::MerchantsController < AdminController
 

  def index
    @merchants = Merchant.find(:all)
  end
  
  def show
    @merchant = Merchant.find_by_id(params[:id])
  end

end