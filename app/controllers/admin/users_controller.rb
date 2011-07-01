class Admin::UsersController < AdminController

  def index
    @users = User.search(params[:search], params[:page])
  end
  
  def show
    @user = User.find_by_id(params[:id])
  end

end