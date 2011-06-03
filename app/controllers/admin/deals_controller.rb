class Admin::DealsController < AdminController
 

  def index
    @deals = Deal.find(:all)
  end
  
  def show
    @deal = Deal.find_by_id(params[:id])
  end

end