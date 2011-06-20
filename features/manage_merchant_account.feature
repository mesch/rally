Feature: Manage Merchant Account
	In order to sell products
	As a merchant
	I want to create and manage a merchant account
	
	Scenario: Signup (basic)
		Given I am on the merchant signup page
		When I fill in "username" with "newbob"
		And I fill in "password" with "test"
		And I fill in "password_confirmation" with "test"
		And I fill in "email" with "test@abc.com"
		And I fill in "name" with "Some Company"
		And I check "tos"
		And I press "Sign Up"
		Then I should see "Log In"
		When I go to the "newbob" subdomain
		Then I should see the generic logo
	
	Scenario: Signup (subdomain)
		Given I am on the merchant signup page
		When I fill in "username" with "newbob"
		And I fill in "password" with "test"
		And I fill in "password_confirmation" with "test"
		And I fill in "email" with "test@abc.com"
		And I fill in "name" with "Some Company"
		And I fill in "subdomain" with "newbob"
		And I check "tos"
		And I press "Sign Up"
		Then I should see "Log In"
		When I go to the "newbob" subdomain
		Then I should see the generic logo
	
	Scenario: Signup (subdomain and logo)	
		Given I am on the merchant signup page
		When I fill in "username" with "newbob"
		And I fill in "password" with "test"
		And I fill in "password_confirmation" with "test"
		And I fill in "email" with "test@abc.com"
		And I fill in "name" with "Some Company"
		And I fill in "subdomain" with "newbob"
		And I upload a logo
		And I check "tos"
		And I press "Sign Up"
		Then I should see "Log In"
		When I go to the "newbob" subdomain
		Then I should see the merchant logo
		
	Scenario: Account (change name)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "name" with "Some Company"
		And I press "Update Account"
		Then I should see "Your account has been updated."
		
	Scenario: Account (change subdomain)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "subdomain" with "newbob"
		And I press "Update Account"
		Then I should see "Your account has been updated."
		
	Scenario: Account (change subdomain and logo)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "subdomain" with "newbob"
		And I upload a logo
		And I press "Update Account"
		Then I should see "Your account has been updated."
		When I go to the "newbob" subdomain
		Then I should see the merchant logo
	
	
	
	
	
	
	
	