Given /^I am logged in as merchant "(.+?)" with password "(.+?)"/ do |username, password|
  visit merchant_login_url
  fill_in "Username", :with => username
  fill_in "Password", :with => password
  click_button "Log In"
  @current_merchant = Merchant.find_by_username(username)
end

Given /^(?:I have|A merchant has) created (?:a deal|deals) titled (.+)$/ do |titles|
  start_date = Time.zone.today
  end_date = Time.zone.today + 1.days
  expiration_date = Time.zone.today + 1.months
  titles.split(', ').each do |title|
    Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00')
  end
end

Given /^(?:I have|A merchant has) published (?:a deal|deals) titled (.+)$/ do |titles|
  start_date = Time.zone.today
  end_date = Time.zone.today + 1.days
  expiration_date = Time.zone.today + 1.months
  titles.split(', ').each do |title|
    Deal.create!(:merchant_id => @current_merchant.id, :title => title, 
      :start_date => start_date, :end_date => end_date, :expiration_date => expiration_date, 
      :deal_price => '10.00', :deal_value => '20.00', :published => true)
  end
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

When /^I upload a file of 10 coupons codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '10codes.csv'))
end

When /^I upload a file of 0 coupons codes$/ do
  attach_file('codes_file', File.join(::Rails.root.to_s, 'features', 'upload-files', '0codes.csv'))
end

Then /^"([^\"]*)" should( not)? be disabled$/ do |label, negate|
  attributes = find_field(label).native.attributes.keys
  attributes.send(negate ? :should_not : :should, include('disabled'))
end
