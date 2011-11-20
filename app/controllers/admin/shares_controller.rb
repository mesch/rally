class Admin::SharesController < AdminController

  def index
    @shares = Share.search(params[:search], params[:page])
  end
  
  def show
    @share = Share.find_by_id(params[:id])
  end

end