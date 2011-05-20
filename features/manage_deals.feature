Feature: Manage Deals
	In order to sell products
	As a merchant
	I want to create and manage deals
	
	Scenario: Deal List
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created deals titled "Cool New Deal", "Dealio"
		When I go to the merchant list of deals
		And I should see "Cool New Deal"
		And I should see "Dealio"
		And I should see "New Deal"
	
	Scenario: Create Deal with 10 codes
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the new deal page
		When I fill in "title" with "Cool New Deal"
		And I fill in "deal_value" with "20"
		And I fill in "deal_price" with "10"
		And I fill in "description" with "A really cool deal."
		And I fill in "terms" with "Some really cool terms..."
		And I upload a valid image for Image 1
		And I upload a file of 10 coupons codes
		And I press "Create Deal"
		Then I should see "Your deal was created successfully."
		And I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should see "Publish"
		
	Scenario: Create Deal with 0 codes
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the new deal page
		When I fill in "title" with "Cool New Deal"
		And I fill in "deal_value" with "20"
		And I fill in "deal_price" with "10"
		And I fill in "description" with "A really cool deal."
		And I fill in "terms" with "Some really cool terms..."
		And I upload a valid image for Image 1
		And I upload a file of 0 coupons codes
		And I press "Create Deal"
		Then I should see "Your deal was created successfully."
		And I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should see "Publish"
	
	Scenario: Edit Deal (Unpublished)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created a deal titled "Cool New Deal"
		And I am on the merchant list of deals
		When I follow "Edit"
		Then "title" should not be disabled
		And "deal_value" should not be disabled
		And "deal_price" should not be disabled
		And "start_date" should not be disabled
		And "end_date" should not be disabled
		And "expiration_date" should not be disabled
		And "min" should not be disabled
		And "max" should not be disabled
		And "limit" should not be disabled
		And "description" should not be disabled
		And "terms" should not be disabled
		And "image1" should not be disabled
		And "image2" should not be disabled
		And "image3" should not be disabled
		And "codes_file" should not be disabled
	
	Scenario: Update Deal (Unpublished)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created a deal titled "Cool New Deal"
		And I am on the edit deal page for "Cool New Deal" 
		When I fill in "title" with "Even Cooler New Deal"
		And I press "Update Deal"
		Then I should see "Your deal was updated successfully."
		And I should see "Even Cooler New Deal"
		
	Scenario: Publish Deal
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created a deal titled "Cool New Deal"
		When I go to the merchant list of deals
		And I follow "Publish"
		Then I should see "Your deal was published successfully."
		And I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should not see "Publish"

	Scenario: Edit Deal (Published)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I am on the merchant list of deals
		When I follow "Edit"
		Then "title" should not be disabled
		And "deal_value" should be disabled
		And "deal_price" should be disabled
		And "start_date" should not be disabled
		And "end_date" should not be disabled
		And "expiration_date" should be disabled
		And "min" should not be disabled
		And "max" should not be disabled
		And "limit" should not be disabled
		And "description" should not be disabled
		And "terms" should not be disabled
		And "image1" should not be disabled
		And "image2" should not be disabled
		And "image3" should not be disabled
		And "codes_file" should be disabled
	
	Scenario: Update Deal (Published)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I am on the edit deal page for "Cool New Deal" 
		When I fill in "title" with "Even Cooler New Deal"
		And I press "Update Deal"
		Then I should see "Your deal was updated successfully."
		And I should see "Even Cooler New Deal"
		