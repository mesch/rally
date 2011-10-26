Feature: View Coupons
	In order to redeem coupons
	As a user
	I want to view coupons
	
	Scenario: Coupon List (Not Logged In)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the list of coupons
		Then I should see "Log In"
	
	Scenario: Coupon List (Active, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 paid coupon with a deal code "abc123"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Active"

	Scenario: Coupon List (Pending, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 authorized coupon with a deal code "abc123"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Pending"

	Scenario: Coupon List (Not Tipped)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 2
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 authorized coupon with a deal code "abc123"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Pending"
	
	Scenario: Coupon List (Expired)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the expiration date of deal "Cool New Deal" to yesterday
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 paid coupon with a deal code "abc123"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "Expired"
	
	Scenario: Coupon Page (Active, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 paid coupon with a deal code "abc123"
		And I am on the list of coupons
		When I follow "Print"
		Then I should see "Coupon"
		And I should see "Cool New Deal"
		And I should see "Redemption Code"
		And I should see "abc123"
		
	Scenario: Coupon Page (Active, With URL Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And the merchant has redemption_type "COUPON_URL"
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 paid coupon with a deal code "http://www.test.com"
		And I am on the list of coupons
		When I follow "Print"
		Then I should see "Coupon"
		And I should see "Cool New Deal"
		And I should see "Redemption URL"
		And I should not see "Redemption Code"
		And I should see "Redemption Link"
		
	Scenario: Coupon Page (Pending, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 authorized coupon with a deal code "abc123"
		And I am on the list of coupons
		Then I should not see "Print"

	Scenario: Coupon Page (Not Tipped)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 2
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 authorized coupon with a deal code "abc123"
		And I am on the list of coupons
		Then I should not see "Print"

	Scenario: Coupon Page (Expired)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the expiration date of deal "Cool New Deal" to yesterday
		And I am logged in as user "empty_user@rallycommerce.com" with password "test"
		And the deal "Cool New Deal" has 1 paid coupon with a deal code "abc123"
		And I am on the list of coupons
		When I follow "Print"
		Then I should see "Coupon"
		And I should see "Cool New Deal"
		And I should see "abc123"
	
	# uses test_user - so this may break if fixture data is removed
	Scenario: Coupon List (non-subdomain)
		Given I am logged in as user "test_user@rallycommerce.com" with password "test"
		When I go to the list of coupons
		Then I should see "Burger Deal!"
		And I should see "Current Deal" 

	# uses test_user - so this may break if fixture data is removed
	Scenario: Coupon List (non-subdomain)
		Given I switch to the "bob" subdomain
		And I am logged in as user "test_user@rallycommerce.com" with password "test"
		When I go to the list of coupons
		Then I should see "Burger Deal!"
		And I should not see "Current Deal"
	
	