class AdminController < ApplicationController
  before_filter :authenticate

  # Use the admin layout
  layout "admin"

  def index
    # Default index for admin section
  end
  
  protected
  
  def authenticate
    authenticate_or_request_with_http_basic do |user_name, password|
      user_name == OPTIONS[:admin_user_name] && password == OPTIONS[:admin_password]
    end
  end
end
