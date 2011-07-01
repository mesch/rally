class Admin::DealsController < AdminController
 

  def index
    @deals = Deal.search(params[:search], params[:page])
  end
  
  def show
    @deal = Deal.find_by_id(params[:id])
  end

end