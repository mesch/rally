Feature: View Facebook Meta Tags
	In order to share deals on facebook
	As a user
	I need to view meta tags

	Scenario: View Deal (facebook meta data)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the deal page for "Cool New Deal"		
		Then I should see the "site_name" facebook meta tag
		And I should see the "url" facebook meta tag
		And I should see the "title" facebook meta tag
		And I should see the "type" facebook meta tag
		And I should see the "image" facebook meta tag
		And I should see the "description" facebook meta tag
		
	Scenario: View Deal List (facebook meta data)
		Given I am on the list of deals page
		Then I should not see the "site_name" facebook meta tag
		And I should not see the "url" facebook meta tag
		And I should not see the "title" facebook meta tag
		And I should not see the "type" facebook meta tag
		And I should not see the "image" facebook meta tag
		And I should not see the "description" facebook meta tag		