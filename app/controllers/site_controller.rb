class SiteController < ApplicationController

  layout "site"

  def home
    redirect_to :controller => :user, :action => :home
  end
  
  def terms
    
  end
  
  def privacy
    
  end
  
  def merchant_terms
    
  end
  
end