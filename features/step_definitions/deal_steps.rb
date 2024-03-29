# Merchant Givens
Given /^I am logged in as merchant "([^"]*)" with password "([^"]*)"/ do |username, password|
  page.driver.post merchant_login_path, :username => username, :password => password
  @current_merchant = Merchant.find_by_username(username)
end

Given /the merchant has redemption_type "([^"]*)"/ do |redemption_type|
  @current_merchant.update_attributes!(:redemption_type => redemption_type)
end
  
Given /^there are no deals$/ do
  Deal.delete_all
end

Given /^(?:I have|a merchant has) created (?:a deal|deals) titled (.+)$/ do |titles|
  # default settings for a deal
  start_date = Time.zone.today.beginning_of_day
  end_date = Time.zone.today.end_of_day
  expiration_date = Time.zone.today.end_of_day + 1.months
  titles.split(', ').each do |title|
    title = title.sub(/^"(.*)"$/,'\1')
    deal = Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00')
    di = DealImage.new(:deal_id => deal.id, :counter => 1)
    di.image = File.new(File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
    di.save!
  end
end

Given /^(?:I have|a merchant has) published (?:a deal|deals) titled (.+)$/ do |titles|
  # default settings for a deal
  start_date = Time.zone.today.beginning_of_day
  end_date = Time.zone.today.end_of_day
  expiration_date = Time.zone.today.end_of_day + 1.months
  titles.split(', ').each do |title|
    title = title.sub(/^"(.*)"$/,'\1')
    deal = Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00', :published => true)
    di = DealImage.new(:deal_id => deal.id, :counter => 1)
    di.image = File.new(File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
    di.save!
  end
end

Given /^(?:I have|a merchant has) changed the (start|end|expiration) date of deal "([^"]*)" to (.+)$/ do |field, title, value|
  date = get_date(value)
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  case field
  when 'start'
    deal.update_attributes!(:start_date => date.beginning_of_day)
  when 'end'
    deal.update_attributes!(:end_date => date.end_of_day)
  when 'expiration'
    deal.update_attributes!(:expiration_date => date.end_of_day)  
  end  
end

Given /^(?:I have|a merchant has) changed the (min|max|limit|deal_price|deal_value) of deal "([^"]*)" to (.+)$/ do |field, title, value|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  deal.update_attributes!(field => value)
end

Given /^(?:I have|a merchant has) added a sharing incentive to deal "([^"]*)"$/ do |title|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  di = DealIncentive.create!(:deal_id => deal.id, :metric_type => DealIncentive::SHARE, 
    :incentive_price => '10.00', :incentive_value => '30.00', :number_required => 1, :max => 100)
end

Given /^(?:I have|a merchant has) changed the (incentive_value|incentive_price|number_required|max) of the sharing incentive for deal "([^"]*)" to (.+)$/ do |field, title, value|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  di = DealIncentive.find_by_deal_id(deal.id)
  di.update_attributes!(field => value)
end

Given /^the deal "([^"]*)" has (\d) (created|authorized|paid) order(?:s)? of (\d) quantity$/ do |title, num_orders, type, quantity|
  num_orders = num_orders.to_i
  quantity = quantity.to_i
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  case type
    when "created" then
      state = Order::CREATED
    when "authorized" then 
      state = Order::AUTHORIZED
    when "paid" then
      state = Order::PAID    
  end
  for i in (1..num_orders)
    Order.create!(:user_id => @current_user.id, :deal_id => deal.id, 
      :quantity => quantity, :amount => quantity*deal.deal_price.to_f,
      :state => state)
  end
end

Given /^the deal "([^"]*)" has 1 (authorized|paid) coupon(?: with a deal code "([^"]*)")?$/ do |title, type, code|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  case type
    when "created" then
      state = Order::CREATED
    when "authorized" then 
      state = Order::AUTHORIZED
    when "paid" then
      state = Order::PAID    
  end
  o = Order.create!(:user_id => @current_user.id, :deal_id => deal.id, :quantity => 1, :amount => 1*deal.deal_price.to_f,
    :state => state)
  if code
    dc = DealCode.create!(:deal_id => 1, :code => code)
    Coupon.create!(:user_id => @current_user.id, :deal_id => deal.id, :order_id => o.id, :deal_code_id => dc.id)
  else
    Coupon.create!(:user_id => @current_user.id, :deal_id => deal.id, :order_id => o.id)    
  end
end

Given /^the deal "([^"]*)" has 1 share$/ do |title|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  Share.create!(:user_id => @current_user.id, :deal_id => deal.id, :facebook_id => 1000)
end

# User Givens
Given /^I am logged in as user "(.+?)" with password "(.+?)"/ do |email, password|
  page.driver.post login_path, :email => email, :password => password
  # switch user
  @current_user = User.find_by_email(email)
end

# Admin Givens
Given /^I am logged in as admin$/ do
  page.driver.browser.basic_authorize(OPTIONS[:admin_user_name], OPTIONS[:admin_password])
end

# When
When /^(?:|I )go to "(.+)"$/ do |url|
  visit url
end

When /^I switch to the "([^"]*)" subdomain$/ do |subdomain|
  Capybara.default_host = "#{subdomain}.#{@base_host}"
  Capybara.app_host = "http://#{subdomain}.#{@base_host}"
end

When /^I upload a valid image for Image 1$/ do 
  attach_file('image1', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a valid image for Image 2$/ do 
  attach_file('image2', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a valid image for Image 3$/ do 
  attach_file('image3', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a file of 10 coupon codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '10codes.csv'))
end

When /^I upload a file of 0 coupon codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '0codes.csv'))
end

When /^I upload a file of 10 incentive codes$/ do
  attach_file('incentive_codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '10codes.csv'))
end

When /^I upload a file of 0 incentive codes$/ do
  attach_file('incentive_codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '0codes.csv'))
end

When /^I upload a file of 10 coupon urls$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '10urlcodes.csv'))
end

When /^I upload a logo$/ do
  attach_file('merchant_logo', File.join(::Rails.root.to_s, 'features', 'upload-files', 'logo.png'))
end

When /^the background process to charge orders is run$/ do
  Deal.charge_orders
end

# Then
Then /^"([^\"]*)" should( not)? be disabled$/ do |label, negate|
  attributes = find_field(label).native.attributes.keys
  attributes.send(negate ? :should_not : :should, include('disabled'))
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, field| 
  find_field(field).value.should =~ /#{value}/ 
end

Then /^I should( not)? see the Buy(?:!)? button$/ do |negate|
  if negate
    page.should_not have_css("img[alt=Transparent]")
  else
    page.should have_css("img[alt=Transparent]")
  end
end

Then /^I should( not)? see the Expired button$/ do |negate|
  if negate
    page.should_not have_css("span[class=deal-price-expire]")
  else
    page.should have_css("span[class=deal-price-expire]")
  end
end

Then /^I should( not)? see the Soldout button$/ do |negate|
  if negate
    page.should_not have_css("span[class=deal-price-soldout]")
  else
    page.should have_css("span[class=deal-price-soldout]")
  end
end

Then /^I should see the limit is (\d)$/ do |limit|
  value = find_field("deal-per-number", :hidden => true).value
  find_field("deal-per-number", :hidden => true).value.should == limit
end

Then /^I should see the generic logo$/ do
  page.should have_xpath("//img[@alt=\"Logo_header\"]")
end

Then /^I should see the merchant logo$/ do
  page.should have_xpath("//img[@alt=\"Header\"]")
end

Then /^I should( not)? see the "([^"]*)" facebook meta tag$/ do |negate, name|
  if negate
    page.should_not have_xpath("//meta[@property=\"og:#{name}\"]")
  else
    page.should have_xpath("//meta[@property=\"og:#{name}\"]")
  end
end

Then /^I should( not)? see the verisign trusted image/ do |negate|
  if negate
    page.should_not have_xpath("//img[@alt=\"verisign_trusted\"]")
  else
    page.should have_xpath("//img[@alt=\"verisign_trusted\"]")
  end    
end

