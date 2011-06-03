class SiteController < ApplicationController

  # Use the user layout (for now?)
  layout "user"

  def home
    redirect_to :controller => :user, :action => :home
  end

  def canvas
    redirect_to :controller => :user, :action => :home
  end
  
  def tos
    
  end
  
  def privacy
    
  end
  
end