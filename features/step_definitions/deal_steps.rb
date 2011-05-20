# Merchant Givens
Given /^(?:I am|a merchant has) logged in as merchant "(.+?)" with password "(.+?)"/ do |username, password|
  visit merchant_login_url
  fill_in "Username", :with => username
  fill_in "Password", :with => password
  click_button "Log In"
  # switch merchant
  @current_merchant = Merchant.find_by_username(username)
end

Given /^there are no deals$/ do
  Deal.delete_all
end

Given /^(?:I have|a merchant has) created (?:a deal|deals) titled (.+)$/ do |titles|
  # default settings for a deal
  start_date = Time.zone.today
  end_date = Time.zone.today
  expiration_date = Time.zone.today + 1.months
  titles.split(', ').each do |title|
    title = title.sub(/^"(.*)"$/,'\1')
    Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00')
  end
end

Given /^(?:I have|a merchant has) published (?:a deal|deals) titled (.+)$/ do |titles|
  # default settings for a deal
  start_date = Time.zone.today
  end_date = Time.zone.today
  expiration_date = Time.zone.today + 1.months
  titles.split(', ').each do |title|
    title = title.sub(/^"(.*)"$/,'\1')
    unless @current_merchant
      @current_merchant = Merchant.find_by_username(:emptybob)
    end
    Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00', :published => true)
  end
end

Given /^(?:I have|a merchant has) changed the (start|end|expiration) date of deal "([^"]*)" to (.+)$/ do |field, title, value|
  date = get_date(value)
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  case field
  when 'start'
    deal.update_attributes!(:start_date => date)
  when 'end'
    deal.update_attributes!(:end_date => date)
  when 'expiration'
    deal.update_attributes!(:expiration_date => date)  
  end  
end

Given /^(?:I have|a merchant has) changed the (min|max|limit) of deal "([^"]*)" to (.+)$/ do |field, title, value|
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  deal.update_attributes!(field => value)
end

Given /^the deal "([^"]*)" has (\d) order of (\d) quantity$/ do |title, num_orders, quantity|
  num_orders = num_orders.to_i
  quantity = quantity.to_i
  deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, title])
  for i in (1..num_orders)
    Order.create!(:user_id => @current_user.id, :deal_id => deal.id, :quantity => quantity, :amount => quantity*deal.deal_price.to_f)
  end
end 	

# User Givens
Given /^I am logged in as user "(.+?)" with password "(.+?)"/ do |username, password|
  visit login_url
  fill_in "Username", :with => username
  fill_in "Password", :with => password
  click_button "Log In"
  # switch user
  @current_user = User.find_by_username(username)
end

# When
When /^I upload a valid image for Image 1$/ do 
  attach_file('image1', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a valid image for Image 2$/ do 
  attach_file('image2', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a valid image for Image 3$/ do 
  attach_file('image3', File.join(::Rails.root.to_s, 'features', 'upload-files', 'valid_image.jpg'))
end

When /^I upload a file of 10 coupons codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '10codes.csv'))
end

When /^I upload a file of 0 coupons codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '0codes.csv'))
end

# Then
Then /^"([^\"]*)" should( not)? be disabled$/ do |label, negate|
  attributes = find_field(label).native.attributes.keys
  attributes.send(negate ? :should_not : :should, include('disabled'))
end

Then /^I should( not)? see the Buy(?:!)? button$/ do |negate|
  #page.should have_xpath("//img[@alt=\'button-deal-buy\']")
  if negate
    page.should_not have_css("img[alt=Button-deal-buy]")
  else
    page.should have_css("img[alt=Button-deal-buy]")
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

