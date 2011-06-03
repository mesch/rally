class Admin::OrdersController < AdminController
 

  def index
    @orders = Order.find(:all, :conditions => ["quantity != 0"])
  end
  
  def show
    @order = Order.find_by_id(params[:id])
  end

end