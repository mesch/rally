Capybara.ignore_hidden_elements = false
Capybara.default_host = 'www.rcom.com'

# load fixtures - before each scenario
Before do
  Fixtures.reset_cache
  fixtures_folder = File.join(::Rails.root.to_s, 'test', 'fixtures')
  fixtures = Dir[File.join(fixtures_folder, '*.yml')].map {|f| File.basename(f, '.yml') }
  Fixtures.create_fixtures(fixtures_folder, fixtures)
end

# default session-based variables
Before do
  @current_merchant = Merchant.find_by_username(:emptybob)
  @current_user = User.find_by_email("empty_user@rallycommerce.com")
  @base_host = "rcom.com"
end
After do
  Capybara.default_host = "www.#{@base_host}"
end

# Helper methods
def get_date(value)
  case value
  when "today"
    date = Time.zone.today
  when "yesterday"
    date = Time.zone.today - 1.days
  when "tomorrow"
    date = Time.zone.today + 1.days
  end
  
  return date
end