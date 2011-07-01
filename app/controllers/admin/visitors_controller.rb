class Admin::VisitorsController < AdminController

  def index
    @visitors = Visitor.find(:all)
  end
  
  def show
    @visitor = Visitor.find_by_id(params[:id])
  end

end