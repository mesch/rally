class Admin::CouponsController < AdminController
 

  def index
    @coupons = Coupon.find(:all)
  end
  
  def show
    @coupon = Coupon.find_by_id(params[:id])
  end

end