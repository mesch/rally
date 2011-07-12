module SubdomainHelper
  
  def redirect_to_subdomain(subdomain)
    new_host = request.host_with_port.gsub(/^#{request.subdomain}(\.)?/, '')
    unless subdomain.empty?
      new_host = [subdomain, new_host].join('.')
    end
    redirect_to :host => new_host, :controller => self.controller_name, :action => self.action_name
    return
  end
  
end