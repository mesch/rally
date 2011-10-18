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
	Scenario: Deal Share (logged in)
		Given a new Facebook user is connected to our app
		And a merchant has published a deal titled "Cool New Deal"
		And I am on the user login page
		When I fill in "email" with "empty_user@rallycommerce.com"
		And I fill in "password" with "test"
		And I press "Log In"
		When I go to the deal page for "Cool New Deal"
		Then I should see "Share:"
		#When I click on the Facebook Share link
		#TODO: can't access pop-up window (selenium bug?)
		#And wait for a while
		#And I log into Facebook
		#And I complete the share
		#Then I should see the popup message "Thank you for sharing!"
		#When I confirm the popup
		#Then I should see "Share:"
		
	@javascript @facebook
	Scenario: Deal Share (not logged in)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the deal page for "Cool New Deal"
		Then I should not see "Share:"

	@javascript @facebook
	Scenario: Facebook Share Page (not logged into FB)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am on the user login page
		When I fill in "email" with "empty_user@rallycommerce.com"
		And I fill in "password" with "test"
		And I press "Log In"	
		When I go to the fb share page for deal "Cool New Deal"
		Then I should not see "Share on Facebook"
		And I should see "You need to log in to Facebook with the proper permissions to share with your friends."
	
	@javascript @facebook
	Scenario: Facebook Share Page (connected to our app, "email" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the fb share page for deal "Cool New Deal"
		Then I should not see "Share on Facebook"
		And I should see "You need to log in to Facebook with the proper permissions to share with your friends."
	
	@javascript @facebook
	Scenario: Facebook Share Page (connected, "email,publish_stream" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email,publish_stream"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the fb share page for deal "Cool New Deal"
		Then I should see "Share on Facebook"
	
	@javascript @facebook
	Scenario: Facebook Share Page (connected, "email,publish_stream,sms" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email,publish_stream,sms"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the fb share page for deal "Cool New Deal"
		Then I should see "Share on Facebook"

	@javascript @facebook
	Scenario: Facebook Share Flow (not logged into FB)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has added a sharing incentive to deal "Cool New Deal"
		And a new Facebook user is not connected to our app
		And I am on the user login page
		When I fill in "email" with "empty_user@rallycommerce.com"
		And I fill in "password" with "test"
		And I press "Log In"	
		When I go to the share page for deal "Cool New Deal"
		And I follow "Share on Facebook"
		Then I should not see "Share on Facebook"
		And I should see "You need to log in to Facebook with the proper permissions to share with your friends."
		# todo: login and get to the fb_share page?

	@javascript @facebook
	Scenario: Facebook Share Flow (connected to our app, "email" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has added a sharing incentive to deal "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the share page for deal "Cool New Deal"
		And I follow "Share on Facebook"
		Then I should not see "Share on Facebook"
		And I should see "You need to log in to Facebook with the proper permissions to share with your friends."
		# todo: login and get to the fb_share page?
	
	@javascript @facebook
	Scenario: Facebook Share Flow (connected, "email,publish_stream" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has added a sharing incentive to deal "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email,publish_stream"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the share page for deal "Cool New Deal"
		And I follow "Share on Facebook"
		Then I should see "Share on Facebook"

	@javascript @facebook
	Scenario: Facebook Share Flow (connected, "email,publish_stream,sms" permissions)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has added a sharing incentive to deal "Cool New Deal"
		And a new Facebook user is connected to our app with permissions "email,publish_stream,sms"
		When I go to the user login page
		And I click on the Facebook Login button
		And I log into Facebook
		When I go to the share page for deal "Cool New Deal"
		And I follow "Share on Facebook"
		Then I should see "Share on Facebook"
