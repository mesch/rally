class Admin::UserActionsController < AdminController

  def index
    @user_actions = UserAction.search(params[:search], params[:page])
  end
  
  def show
    @user_action = UserAction.find_by_id(params[:id])
  end

end