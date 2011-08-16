Feature: Manage Admin Account
	In order to assist merchants creating deals
	As an
	I want to manage the admin account
	
	Scenario: Create Merchant Account (basic)
		Given I am logged in as admin
		And I am on the admin new merchant page
		When I fill in "merchant_username" with "newbob"
		And I fill in "merchant_password" with "test"
		And I fill in "merchant_password_confirmation" with "test"
		And I fill in "merchant_email" with "test@abc.com"
		And I fill in "merchant_name" with "Some Company"
		And I press "Create Merchant"
		Then I should see "Merchants"
		And I should see "newbob"
		When I go to the admin edit merchant page for "newbob"
		Then I should see "Send Activation Email"
		When I go to the "newbob" subdomain
		Then I should see the generic logo

	Scenario: Create Merchant Account (subdomain)
		Given I am logged in as admin
		And I am on the admin new merchant page
		When I fill in "merchant_username" with "newbob"
		And I fill in "merchant_password" with "test"
		And I fill in "merchant_password_confirmation" with "test"
		And I fill in "merchant_email" with "test@abc.com"
		And I fill in "merchant_name" with "Some Company"
		And I fill in "merchant_subdomain" with "newbob"
		And I press "Create Merchant"
		Then I should see "Merchants"
		And I should see "newbob"
		When I go to the admin edit merchant page for "newbob"
		Then I should see "Send Activation Email"
		When I go to the "newbob" subdomain
		Then I should see the generic logo
	
	Scenario: Create Merchant Account (subdomain and logo)
		Given I am logged in as admin
		And I am on the admin new merchant page
		When I fill in "merchant_username" with "newbob"
		And I fill in "merchant_password" with "test"
		And I fill in "merchant_password_confirmation" with "test"
		And I fill in "merchant_email" with "test@abc.com"
		And I fill in "merchant_name" with "Some Company"
		And I fill in "merchant_subdomain" with "newbob"
		And I upload a logo
		And I press "Create Merchant"
		Then I should see "Merchants"
		And I should see "newbob"
		When I go to the admin edit merchant page for "newbob"
		Then I should see "Send Activation Email"
		When I go to the "newbob" subdomain
		Then I should see the merchant logo

	Scenario: Edit Merchant Account (change name)
		Given I am logged in as admin
		When I go to the admin edit merchant page for "emptybob"
		When I fill in "merchant_name" with "Some Company"
		And I press "Update Merchant"	
		Then I should see "Merchants"
		And I should see "Account updated."
		When I go to the admin edit merchant page for "emptybob"
		Then the "merchant_name" field should contain "Some Company"
		When I go to the "newbob" subdomain
		Then I should see the generic logo	

	Scenario: Edit Merchant Account (subdomain)
		Given I am logged in as admin
		When I go to the admin edit merchant page for "emptybob"
		When I fill in "merchant_subdomain" with "newbob"
		And I press "Update Merchant"	
		Then I should see "Merchants"
		And I should see "Account updated."
		When I go to the admin edit merchant page for "emptybob"
		Then the "merchant_subdomain" field should contain "newbob"
		When I go to the "newbob" subdomain
		Then I should see the generic logo

	Scenario: Edit Merchant Account (subdomain and logo)
		Given I am logged in as admin
		When I go to the admin edit merchant page for "emptybob"
		When I fill in "merchant_subdomain" with "newbob"
		And I upload a logo
		And I press "Update Merchant"
		Then I should see "Merchants"
		And I should see "Account updated."
		When I go to the admin edit merchant page for "emptybob"
		Then the "merchant_subdomain" field should contain "newbob"
		When I go to the "newbob" subdomain
		Then I should see the merchant logo	

	Scenario: Send Activation Email
		Given I am logged in as admin
		When I go to the admin edit merchant page for "inactivated"
		When I follow "Send Activation Email"
		Then I should see "Edit Account"
		And I should see "Activation email has been sent."
	
	Scenario: View Merchant Report (empty)
		Given I am logged in as admin
		When I go to the admin merchant reports page for "emptybob"
		Then I should see "Reports"
		And I should not see "Download"
		And I should not see "Delete"

	Scenario: Generate Report (Coupon Report)
		Given I am logged in as admin
		And a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		And I am on the admin merchant reports page for "emptybob"
		When I follow "New Report"
		And I select "COUPON_REPORT" from "report_type"
		And I select "Cool New Deal" from "deal_id"
		And I press "Generate Report"
		Then I should see "Reports"
		And I should see "Your report is generating."
		And I should see "Download"
		And I should see "Delete"
		
	Scenario: Generate Report (Coupon Report - all)
		Given I am logged in as admin
		And a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		And I am on the admin merchant reports page for "emptybob"
		When I follow "New Report"
		And I select "COUPON_REPORT" from "report_type"
		And I select "Cool New Deal" from "deal_id"
		And I check "all"
		And I press "Generate Report"
		Then I should see "Reports"
		And I should see "Your report is generating."
		And I should see "Download"
		And I should see "Delete"
		
	Scenario: Delete Report
		Given I am logged in as admin
		And a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		And I am on the admin merchant reports page for "emptybob"
		When I follow "New Report"
		And I select "COUPON_REPORT" from "report_type"
		And I select "Cool New Deal" from "deal_id"
		And I press "Generate Report"
		Then I should see "Reports"
		And I should see "Your report is generating."
		And I should see "Download"
		And I should see "Delete"
		When I follow "Delete"
		And show me the page
		Then I should see "Reports"
		And I should see "Your report was deleted."
		And I should not see "Download"
		And I should not see "Delete"
