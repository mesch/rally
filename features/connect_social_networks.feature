Feature: Manage User Account
	In order to share deals
	As a user
	I want to connect and post to my social network accounts

	@javascript @facebook
	Scenario: FB Signup (have added app)
		Given a new Facebook user is connected to our app
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		Then I should see "Welcome,"
		And the user should be confirmed on the backend
		When I follow "Log Out"
		Then I should see "Log In"
		When I click on the Facebook Login button
		Then I should see "Welcome,"
	
	@javascript @facebook
	Scenario: FB Signup (haven't added app)
		Given a new Facebook user is not connected to our app
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		And I accept the Facebook app permissions
		Then I should see "Welcome,"
		And the user should be confirmed on the backend
		When I follow "Log Out"
		Then I should see "Log In"
		When I click on the Facebook Login button
		Then I should see "Welcome,"

	@javascript @facebook
	Scenario: FB Share (logged in)
		Given a new Facebook user is connected to our app
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the user login page
		When I fill in "email" with "empty_user@rallycommerce.com"
		And I fill in "password" with "test"
		And I press "Log In"
		When I go to the deal page for "Cool New Deal"
		Then I should see "Share:"
		When I click on the Facebook Share link
		#TODO: can't access pop-up window (selenium bug?)
		#And wait for a while
		#And I log into Facebook
		#And I complete the share
		#Then I should see the popup message "Thank you for sharing!"
		#When I confirm the popup
		#Then I should see "Share:"

	@javascript @facebook
	Scenario: FB Share (not logged in)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the deal page for "Cool New Deal"
		Then I should not see "Share:"	
	
	