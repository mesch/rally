# Given
Given /^I am using the remote test environment$/ do
  Capybara.app_host = 'http://rallycommerce-test.heroku.com'
end