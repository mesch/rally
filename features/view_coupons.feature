Feature: View Coupons
	In order to redeem coupons
	As a user
	I want to view coupons
	
	Scenario: Coupon List (Not Logged In)
		Given a merchant has published a deal titled "Cool New Deal"
		When I go to the list of coupons
		Then I should see "User Login"
	
	Scenario: Coupon List (Active, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "abc123"
		And I should see "Active"

	Scenario: Coupon List (Active, Without Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And the deal "Cool New Deal" has 1 coupon
		And I am logged in as user "empty_user" with password "test"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should not see "abc123"
		And I should see "Active"

	Scenario: Coupon List (Not Tipped)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 2
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "abc123"
		And I should see "Pending"
	
	Scenario: Coupon List (Expired)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the expiration date of deal "Cool New Deal" to yesterday
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		When I go to the list of coupons
		Then I should see "Coupons"
		And I should see "Cool New Deal"
		And I should see "abc123"
		And I should see "Expired"
	
	Scenario: Coupon Page (Active, With Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		And I am on the list of coupons
		When I follow "View"
		Then I should see "Coupon"
		And the "title" field should contain "Cool New Deal"
		And the "code" field should contain "abc123"
		And the "state" field should contain "Active"

	Scenario: Coupon Page (Active, Without Deal Code)
		Given a merchant has published a deal titled "Cool New Deal"
		And the deal "Cool New Deal" has 1 coupon
		And I am logged in as user "empty_user" with password "test"
		And I am on the list of coupons
		When I follow "View"
		Then I should see "Coupon"
		And the "title" field should contain "Cool New Deal"
		And the "code" field should not contain "abc123"
		And the "state" field should contain "Active"

	Scenario: Coupon Page (Not Tipped)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the min of deal "Cool New Deal" to 2
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		And I am on the list of coupons
		When I follow "View"
		Then I should see "Coupon"
		And the "title" field should contain "Cool New Deal"
		And the "code" field should contain "abc123"
		And the "state" field should contain "Pending"

	Scenario: Coupon Page (Expired)
		Given a merchant has published a deal titled "Cool New Deal"
		And a merchant has changed the expiration date of deal "Cool New Deal" to yesterday
		And the deal "Cool New Deal" has 1 coupon with a deal code "abc123"
		And I am logged in as user "empty_user" with password "test"
		And I am on the list of coupons
		When I follow "View"
		Then I should see "Coupon"
		And the "title" field should contain "Cool New Deal"
		And the "code" field should contain "abc123"
		And the "state" field should contain "Expired"
	