module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    # merchant
    when /the merchant signup page/
      merchant_signup_path
    when /the merchant account page/
      merchant_account_path
    when /the merchant home\s?page/
      merchant_home_path
    when /the merchant list of deals/
      merchant_deals_path
    when /the new deal page/
      merchant_new_deal_path
    when /the edit deal page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      merchant_edit_deal_path(deal.id)
    # user
    when /the user signup page/
      signup_path
    when /the user account page/
      account_path
    when /the user login page/
      login_path
    when /the list of deals/
      deals_path
    when /the deal page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      deal_path(deal.id)
    when /the order page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      payment_order_path(:deal_id => deal.id)    
    when /the list of coupons/
      coupons_path
    when /the share page for deal "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      share_path(:deal_id => deal.id)
    when /the fb share page for deal "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      fb_share_path(:deal_id => deal.id)
    # admin
    when /the admin home page/
      admin_home_path
    when /the admin list of merchants/
      admin_merchants_path
    when /the admin new merchant page/
      new_admin_merchant_path
    when /the admin edit merchant page for "([^"]*)"/
      merchant = Merchant.find_by_username($1)
      edit_admin_merchant_path(merchant.id)
    when /the admin merchant reports page for "([^"]*)"/
      merchant = Merchant.find_by_username($1)
      reports_admin_merchant_path(merchant.id)      
    # subdomain
    when /the "([^"]*)" subdomain/       
      url = "http://#{$1}.#{@base_host}"
    # facebook
    when /the list of deals from facebook/
      facebook_deals_path
    when /the order page from facebook for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      facebook_payment_order_deal_path(:deal_id => deal.id)
      
    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
