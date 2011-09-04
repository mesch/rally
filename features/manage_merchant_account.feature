Feature: Manage Merchant Account
	In order to sell products
	As a merchant
	I want to create and manage a merchant account
		
	Scenario: Account (change name)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "merchant_name" with "Some Company"
		And I press "Update Account"
		Then I should see "Your account has been updated."
		And I should see the generic logo
		
	Scenario: Account (change subdomain)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "merchant_subdomain" with "newbob"
		And I press "Update Account"
		Then I should see "Your account has been updated."
		And I should see the generic logo
		
	Scenario: Account (change subdomain and logo)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the merchant account page
		When I fill in "merchant_subdomain" with "newbob"
		And I upload a logo
		And I press "Update Account"
		Then I should see "Your account has been updated."
		And I should see the merchant logo
		When I go to the "newbob" subdomain
		Then I should see the merchant logo

	
	
	
	
	
	