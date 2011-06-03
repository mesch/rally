class Admin::PaymentsController < AdminController
 

  def index
    @payments = OrderPayment.find(:all)
  end
  
  def show
    @payment = OrderPayment.find_by_id(params[:id])
  end

end