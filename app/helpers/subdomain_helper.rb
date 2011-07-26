require 'subdomain'

module SubdomainHelper
  
  def redirect_to_subdomain(subdomain)
    new_host = new_host_subdomain(request, subdomain)
    redirect_to :host => new_host, :controller => self.controller_name, :action => self.action_name
    return
  end
  
end