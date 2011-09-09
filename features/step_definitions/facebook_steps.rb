# Given
Given /^a new Facebook user is( not)? connected to our app$/ do |negate|
  if negate
    @fb_user = create_fb_test_user(false)
  else
    @fb_user = create_fb_test_user(true)
  end
end

Given /^a user exists tied to the Facebook user$/ do
  assert User.create(:facebook_id => @fb_user["id"], :email => @fb_user["email"], :activated => true)
end

# When
When /^wait for a while$/ do
  sleep(30)
end

When /^I click on the Facebook Login button$/ do
  page.find_by_id("facebook-login-button").click
end

When /^I click on the Facebook Share link$/ do
  #page.find(:xpath, "//a/img[@alt='fb-share-link']/..").click
  page.find_by_id("facebook-share-link").click
end

When /^I log into Facebook$/ do
  within_window(page.driver.browser.window_handles.last) do 
    fill_in('email', :with => @fb_user['email'])
    fill_in('pass', :with => @fb_user['password'])
    click_on('Log In')
  end
end

When /^I accept the Facebook app permissions$/ do
  within_window(page.driver.browser.window_handles.last) do 
    click_on('Allow')
  end
end

When /^I complete the share$/ do
  within_window(page.driver.browser.window_handles.last) do 
    click_on('Share')
  end  
end

When /^I confirm the popup$/ do
  page.driver.browser.switch_to.alert.accept    
end

When /^I dismiss the popup$/ do
  page.driver.browser.switch_to.alert.dismiss
end

# Then
Then /^the user should be confirmed on the backend$/ do
  assert User.find_by_email(@fb_user['email'])
end

Then /^I should see the popup message "([^"]*)"$/ do |message|
  dialog = page.driver.browser.switch_to.alert
  p dialog.text
  assert_equal dialog.text, message
end