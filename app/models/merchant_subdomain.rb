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
  
  def get_css(type='site')
    if self.merchant
      scss_file = "#{self.merchant.id}_#{type}.scss"
      full_path = File.join(Rails.root, Compass.configuration.sass_dir, scss_file)
      if File.exists?(full_path)
        file_name = scss_file.gsub(/\.scss$/, '')
        return file_name
      end
    end
    return nil
  end
  
  def verisign_trusted?
    if self.subdomain == 'www'
      return true
    end
    if self.merchant
      return self.merchant.verisign_trusted
    end
    return false
  end
  
end
