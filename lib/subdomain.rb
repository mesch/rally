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
