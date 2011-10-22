Feature: Manage Deals
	In order to sell products
	As a merchant
	I want to create and manage deals
	
	Scenario: Deal List (No deals)
		Given I am logged in as merchant "emptybob" with password "test"
		And I go to the merchant list of deals
		Then I should see "You do not have any drafts"
		When I follow "Current Deals"
		Then I should see "You do not have any current deals"
		When I follow "Good Deals"
		Then I should see "You do not have any deals"
		When I follow "Failed Deals"
		Then I should see "You do not have any failed deals"
			
	Scenario: Deal List (Draft - multiple)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created deals titled "Cool New Deal", "Dealio"
		When I go to the merchant list of deals
		Then I should see "Cool New Deal"
		And I should see "Dealio"
		And I should see "New Deal"
		When I follow "Current Deals"
		Then I should not see "Cool New Deal"
		And I should not see "Dealio"
		When I follow "Good Deals"
		Then I should not see "Cool New Deal"
		And I should not see "Dealio"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"
		And I should not see "Dealio"
		
	Scenario: Deal List (Draft - single)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created deals titled "Cool New Deal"
		When I go to the merchant list of deals
		Then I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should see "Publish"
		And I should see "Delete"
		And I should not see "Force Tip"
		
	Scenario: Deal List (Draft - single ended)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created a deal titled "Cool New Deal"
		And I have changed the start date of deal "Cool New Deal" to yesterday		
		And I have changed the end date of deal "Cool New Deal" to yesterday
		When I go to the merchant list of deals
		Then I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should see "Publish"
		And I should see "Delete"
		And I should not see "Force Tip"
		
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
		And I should see "Delete"
		And I should not see "Force Tip"
		
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
		And I should see "Delete"
		And I should not see "Force Tip"
	
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

	Scenario: Delete Deal
		Given I am logged in as merchant "emptybob" with password "test"
		And I have created a deal titled "Cool New Deal"
		When I go to the merchant list of deals
		And I follow "Delete"
		Then I should see "Your draft was deleted."
		And I should see "Drafts"
		And I should not see "Cool New Deal"
		When I follow "Current Deals"
		Then I should not see "Cool New Deal"
		When I follow "Good Deals"
		Then I should not see "Cool New Deal"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"
		
	Scenario: Publish Deal
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
		When I go to the merchant list of deals
		And I follow "Publish"
		Then I should see "Your deal was published successfully."
		And I should see "Current Deals"
		And I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should not see "Publish"
		And I should not see "Delete"
		And I should not see "Force Tip"
		When I follow "Drafts"
		Then I should not see "Cool New Deal"
		When I follow "Good Deals"
		Then I should not see "Cool New Deal"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"
		
	Scenario: Publish Deal (no deal codes)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the new deal page
		When I fill in "title" with "Cool New Deal"
		And I fill in "deal_value" with "20"
		And I fill in "deal_price" with "10"
		And I fill in "description" with "A really cool deal."
		And I fill in "terms" with "Some really cool terms..."
		And I upload a valid image for Image 1
		And I press "Create Deal"
		Then I should see "Your deal was created successfully."
		When I go to the merchant list of deals
		And I follow "Publish"
		Then I should see "You must upload coupon codes before you can publish."
		And I should see "Drafts"
		And I should see "Cool New Deal"
		
	Scenario: Publish Deal (no deal images)
		Given I am logged in as merchant "emptybob" with password "test"
		And I am on the new deal page
		When I fill in "title" with "Cool New Deal"
		And I fill in "deal_value" with "20"
		And I fill in "deal_price" with "10"
		And I fill in "description" with "A really cool deal."
		And I fill in "terms" with "Some really cool terms..."
		And I upload a file of 10 coupons codes
		And I press "Create Deal"
		Then I should see "Your deal was created successfully."
		When I go to the merchant list of deals
		And I follow "Publish"
		Then I should see "You must upload at least one image before you can publish."
		And I should see "Drafts"
		And I should see "Cool New Deal"

	Scenario: Deal List (Published)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		When I go to the merchant list of deals
		Then I should not see "Cool New Deal"
		When I follow "Current Deals"
		Then I should see "Cool New Deal"
		And I should see "Edit"
		And I should see "View"
		And I should not see "Publish"
		And I should not see "Delete"
		And I should not see "Force Tip"		
		When I follow "Good Deals"
		Then I should not see "Cool New Deal"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"			

	Scenario: Edit Deal (Published)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I am on the merchant list of deals
		When I follow "Current Deals"
		And I follow "Edit"
		Then "title" should not be disabled
		And "deal_value" should be disabled
		And "deal_price" should be disabled
		And "start_date" should not be disabled
		And "end_date" should not be disabled
		And "expiration_date" should be disabled
		And "min" should be disabled
		And "max" should be disabled
		And "limit" should be disabled
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
		
	Scenario: Deal List (Good Deal)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I have changed the end date of deal "Cool New Deal" to yesterday
		When I go to the merchant list of deals
		Then I should not see "Cool New Deal"
		When I follow "Current Deals"
		Then I should not see "Cool New Deal"
		When I follow "Good Deals"
		Then I should see "Cool New Deal"
		And I should see "View"
		And I should not see "Edit"
		And I should not see "Publish"
		And I should not see "Delete"
		And I should not see "Force Tip"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"

	Scenario: Deal List (Failed Deal)
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I have changed the end date of deal "Cool New Deal" to yesterday
		And I have changed the min of deal "Cool New Deal" to 1
		When I go to the merchant list of deals
		Then I should not see "Cool New Deal"
		When I follow "Current Deals"
		Then I should not see "Cool New Deal"
		When I follow "Good Deals"
		Then I should not see "Cool New Deal"
		When I follow "Failed Deals"
		Then I should see "Cool New Deal"
		And I should see "View"
		And I should not see "Edit"
		And I should not see "Publish"
		And I should not see "Delete"
		And I should see "Force Tip"
		
	Scenario: Publish Deal
		Given I am logged in as merchant "emptybob" with password "test"
		And I have published a deal titled "Cool New Deal"
		And I have changed the end date of deal "Cool New Deal" to yesterday
		And I have changed the min of deal "Cool New Deal" to 1	
		When I go to the merchant list of deals
		And I follow "Failed Deals"
		And I follow "Force Tip"
		Then I should see "Your deal is tipped."
		And I should see "Good Deals"
		And I should see "Cool New Deal"
		And I should see "View"
		And I should not see "Edit"
		And I should not see "Publish"
		And I should not see "Delete"
		And I should not see "Force Tip"
		When I follow "Drafts"
		Then I should not see "Cool New Deal"
		When I follow "Current Deals"
		Then I should not see "Cool New Deal"
		When I follow "Failed Deals"
		Then I should not see "Cool New Deal"