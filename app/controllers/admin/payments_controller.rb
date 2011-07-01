class Admin::PaymentsController < AdminController

  def index
    @payments = OrderPayment.search(params[:search], params[:page])
  end
  
  def show
    @payment = OrderPayment.find_by_id(params[:id])
  end

end