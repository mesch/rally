class Admin::OrdersController < AdminController
 

  def index
    @orders = Order.search(params[:search], params[:page])
  end
  
  def show
    @order = Order.find_by_id(params[:id])
  end

end