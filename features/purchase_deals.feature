Feature: Purchase Deals
	In order to obtain coupons
	As a user
	I want to buy deals
	
	@deploy
	Scenario: Full Purchase 
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1220"
		And I press "Purchase"
		Then show me the page
		And I should see "Thank you for your purchase!"
		When I press "Coupons"
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Pending"
	
	@deploy
	Scenario: Full Purchase (invalid credit card)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		When I fill in "x_card_num" with "4000000000001"
		And I fill in "x_exp_date" with "1220"
		And I press "Purchase"
		Then I should see "Purchase"
		And I should see "There was a problem approving your transaction. Please try again."

	@deploy
	Scenario: Full Purchase (invalid expiration date)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1210"
		And I press "Purchase"
		Then I should see "Purchase"
		And I should see "There was a problem approving your transaction. Please try again."
	
	@deploy
	Scenario: Full Purchase (with background process)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1220"
		And I press "Purchase"
		Then I should see "Thank you for your purchase!"
		When the background process to charge orders is run
		And I press "Coupons"
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Active"

	@deploy
	Scenario: Full Purchase (not-tipped with background process)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 2
		And I am logged in as user "empty_user" with password "test"
		And I am on the order page for "Cool New Deal"
		When I press "Confirm Order"
		Then I should see "Purchase"
		When I fill in "x_card_num" with "4007000000027"
		And I fill in "x_exp_date" with "1220"
		And I press "Purchase"
		Then I should see "Thank you for your purchase!"
		When the background process to charge orders is run
		And I press "Coupons"
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Pending"		
	