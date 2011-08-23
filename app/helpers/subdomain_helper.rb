require 'subdomain'

module SubdomainHelper
  
  def redirect_to_subdomain(subdomain, params={})
    new_host = new_host_subdomain(request, subdomain)
    all_params = { :host => new_host, :controller => self.controller_name, :action => self.action_name }.merge(params)
    redirect_to all_params
    return
  end
  
end