Feature: Purchase Deals
	In order to obtain coupons
	As a user
	I want to buy deals
	
	@wip
	Scenario: Full Purchase 
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		And show me the page
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1220"
		And I press "Purchase"
		Then I should see "Thank you for your purchase!"
		When I press "Coupons"
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Pending"
	
	@wip
	Scenario: Full Purchase (error)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		And show me the page
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1210"
		And I press "Purchase"
		# what to check for?	
		
	