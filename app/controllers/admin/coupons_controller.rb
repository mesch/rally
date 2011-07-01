class Admin::CouponsController < AdminController
 

  def index
    @coupons = Coupon.search(params[:search], params[:page])
  end
  
  def show
    @coupon = Coupon.find_by_id(params[:id])
  end

end