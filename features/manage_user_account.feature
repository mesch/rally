Feature: Manage User Account
	In order to buy products
	As a user
	I want to create and manage a user account
	
	Scenario: Signup (basic)
		Given I am on the user signup page
		When I fill in "email" with "test@abc.com"
		And I fill in "password" with "test"
		And I fill in "password_confirmation" with "test"
		And I fill in "first_name" with "Tester"
		And I fill in "last_name" with "Testerson"
		And I check "terms"
		And I press "Sign Up"
		Then I should see "Log In"
		
	Scenario: Account (change name)
		Given I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And I am on the user account page
		When I fill in "first_name" with "Testerly"
		And I press "Update Account"
		Then I should see "Your account has been updated."
		And the "first_name" field should contain "Testerly"
