Feature: Buy Deals
	In order to buy deals
	As a user
	I want to view and purchase deals
	
	Scenario: Deal List
		Given a merchant has published deals titled "Cool New Deal", "Dealio"
		When I go to the list of deals
		Then I should see "Cool New Deal"
		And I should see "Dealio"
	
	Scenario: Deal List (Unpublished)
		Given a merchant has created a deal titled "Cool New Deal"
		When I go to the list of deals
		Then I should not see "Cool New Deal"

	Scenario: Deal List (Hasn't started)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the start date of deal "Cool New Deal" to tomorrow
		When I go to the list of deals
		Then I should not see "Cool New Deal"

	Scenario: Deal List (Has ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		When I go to the list of deals
		Then I should not see "Cool New Deal"

	Scenario: Deal page - Other Deals
		Given there are no deals
		And a merchant has published a deal titled "Dealio"
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the list of deals
		When I follow "Cool New Deal"
		Then I should see "Dealio"

	Scenario: Deal page - Other Deals (Unpublished)
		Given there are no deals
		And a merchant has created a deal titled "Dealio"
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the list of deals
		When I follow "Cool New Deal"
		Then I should not see "Dealio"

	Scenario: Deal page - Other Deals (Hasn't started)
		Given there are no deals
		And a merchant has published a deal titled "Dealio"
		And a merchant has changed the start date of deal "Dealio" to tomorrow
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the list of deals
		When I follow "Cool New Deal"
		Then I should not see "Dealio"
			
	Scenario: Deal page - Other Deals (Has ended)
		Given there are no deals
		And a merchant has published a deal titled "Dealio"
		And a merchant has changed the end date of deal "Dealio" to yesterday
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the list of deals
		When I follow "Cool New Deal"
		Then I should not see "Dealio"

	Scenario: Deal Page (Not Tipped, Not Maxed, Not Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 1
		When I go to the deal page for "Cool New Deal"
		Then I should see the Buy! button
		And I should not see the Expired button
		And I should not see the Soldout button
		And I should see "Buy 1 More To Tip This Deal!"
		And I should not see "The deal is tipped!"
		And I should not see "Total 0 bought."
	
	Scenario: Deal Page (Not Tipped, Not Maxed, Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 1
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		When I go to the deal page for "Cool New Deal"
		Then I should not see the Buy button
		And I should see the Expired button
		And I should not see the Soldout button
		And I should not see "Buy 1 More To Tip This Deal!"
		And I should not see "The deal is tipped!"
		And I should see "Total 0 bought."
	
	Scenario: Deal Page (Tipped, Not Maxed, Not Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the deal page for "Cool New Deal"
		Then I should see the Buy button
		And I should not see the Expired button
		And I should not see the Soldout button
		And I should not see "Buy 1 More To Tip This Deal!"
		And I should see "The deal is tipped!"
		And I should not see "Total 0 bought."
	
	Scenario: Deal Page (Tipped, Not Maxed, Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		When I go to the deal page for "Cool New Deal"
		Then I should not see the Buy button
		And I should see the Expired button
		And I should not see the Soldout button
		And I should not see "Buy 1 More To Tip This Deal!"
		And I should not see "The deal is tipped!"
		And I should see "Total 0 bought."
	
	Scenario: Deal Page (Tipped, Maxed, Not Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the max of deal "Cool New Deal" to 1
		And the deal "Cool New Deal" has 1 order of 1 quantity	
		When I go to the deal page for "Cool New Deal"
		Then I should not see the Buy button
		And I should not see the Expired button
		And I should see the Soldout button
		And I should not see "Buy 0 More To Tip This Deal!"
		And I should see "The deal is tipped!"
		And I should not see "Total 1 bought."
	
	Scenario: Deal Page (Tipped, Maxed, Ended)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the end date of deal "Cool New Deal" to yesterday
		And a merchant has changed the max of deal "Cool New Deal" to 1
		And the deal "Cool New Deal" has 1 order of 1 quantity	
		When I go to the deal page for "Cool New Deal"
		Then I should not see the Buy button
		And I should not see the Expired button
		And I should see the Soldout button
		And I should not see "Buy 1 More To Tip This Deal!"
		And I should not see "The deal is tipped!"
		And I should see "Total 1 bought."