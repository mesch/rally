class Subdomain
  def self.matches?(request)
    request.subdomain.present? && request.subdomain != "www"
  end
end

class APISubdomain < Subdomain
  def self.matches?(request)
    super && request.subdomain == "api"
  end
end

def new_host_subdomain(host, old_subdomain, new_subdomain)
  new_host = host.gsub(/^#{old_subdomain}(\.)?/, '')
  unless new_subdomain.empty?
    new_host = [new_subdomain, new_host].join('.')
  end
  return new_host
end

def base_host(request)
  return new_host_subdomain(request.host_with_port, request.subdomain, '')
end

  