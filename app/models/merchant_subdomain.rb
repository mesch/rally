class MerchantSubdomain < ActiveRecord::Base
  validates_presence_of :subdomain
  validates_uniqueness_of :subdomain
  
  attr_protected :id
  
  belongs_to :merchant
  
  def get_logo
    if self.merchant
      return self.merchant.get_logo
    end
    return nil
  end
  
  def get_logo_footer
    if self.merchant
      return self.merchant.get_logo_footer
    end
    return nil
  end   
  
end
