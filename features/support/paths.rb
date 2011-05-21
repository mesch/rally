module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the merchant home\s?page/
      merchant_home_path
    when /the merchant list of deals/
      merchant_deals_path
    when /the new deal page/
      merchant_new_deal_path
    when /the edit deal page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      merchant_edit_deal_path(deal.id)
    when /the list of deals/
      deals_path
    when /the deal page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      deal_path(deal.id)
    when /the order page for "([^"]*)"/
      deal = Deal.find(:first, :conditions => ["merchant_id = ? AND title = ?", @current_merchant.id, $1])
      payment_order_path(:deal_id => deal.id)    
      

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
