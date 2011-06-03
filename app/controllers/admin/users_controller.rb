class Admin::UsersController < AdminController
 

  def index
    @users = User.find(:all)
  end
  
  def show
    @user = User.find_by_id(params[:id])
  end

end