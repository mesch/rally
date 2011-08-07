# simple script to make sure environments are up
require 'net/http'
require 'net/smtp'

PRODUCTION_HOST = 'www.shopnrally.com'
DEMO_HOST = 'www.rallycommerce.net'
TIMEOUT = 5 # seconds
MAX_TRIES = 3

class HTTPError < RuntimeError

end

def send_mail(host)
  message = "From: Admin <admin@rallycommerce.com>\nTo: mesch <matt@rallycommerce.com>\nSubject: #{host} is down!"
  smtp = Net::SMTP.new('smtp.gmail.com', 587)
  smtp.enable_starttls
  smtp.start('localhost', 'admin@rallycommerce.com', 'etothexdx', :plain) do |server|
    server.send_message message, 'admin@rallycommerce.com', 'matt@rallycommerce.com'
  end
end

def check(host)
  http = Net::HTTP.new(host)
  http.open_timeout = TIMEOUT
  http.read_timeout = TIMEOUT
  tries = 0
  begin
    response =  http.request_get('/deals')
    unless (response.code =~ /^2|3\d{2}$/)
      raise HTTPError
    end
  rescue Timeout::Error
    tries += 1
    if tries < MAX_TRIES
      sleep(10)
      retry
    end
    # mail error
    send_mail(host)
  rescue HTTPError
    tries += 1
    if tries < MAX_TRIES
      sleep(10)
      retry
    end
    # mail error
    send_mail(host)
  end
end

check(DEMO_HOST)
check(PRODUCTION_HOST)

