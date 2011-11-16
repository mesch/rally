class Admin::DealsController < AdminController
 

  def index
    @deals = Deal.search(params[:search], params[:page])
  end
  
  def show
    @deal = Deal.find_by_id(params[:id])
  end
  
  def deal_codes
    @deal = Deal.find_by_id(params[:id])
    
    @deal_codes = DealCode.search(@deal.id, params[:page])
  end

  def deal_incentive
    @deal = Deal.find_by_id(params[:id])
    
    @deal_incentives = DealIncentive.search(@deal.id, params[:page])
  end    

end