module Facebook

  def get_fb_user
    oauth = Koala::Facebook::OAuth.new(OPTIONS[:facebook_app_id], OPTIONS[:facebook_secret_key])
    user_info = oauth.get_user_info_from_cookies(cookies)
    if user_info && user_info["access_token"] && user_info["uid"]
      graph = Koala::Facebook::GraphAPI.new(user_info["access_token"])
      begin
        fb_user = graph.get_object(user_info["uid"])
      rescue Koala::Facebook::APIError => fe
        logger.error "Facebook.get_fb_user: #{fe}"
        return nil
      end
    end
    return fb_user
  end
  
  def get_fb_user_permissions
    p "Calling fb_user_permissions"
    oauth = Koala::Facebook::OAuth.new(OPTIONS[:facebook_app_id], OPTIONS[:facebook_secret_key])
    user_info = oauth.get_user_info_from_cookies(cookies)
    p user_info
    if user_info && user_info["access_token"] && user_info["uid"]
      graph = Koala::Facebook::GraphAPI.new(user_info["access_token"])
      begin
        fb_user = graph.get_object(user_info["uid"])
        p fb_user
        data = fb_user = graph.get_connections(user_info["uid"], "permissions")
        p data
        permissions = data[0]
      rescue Koala::Facebook::APIError => fe
        logger.error "Facebook.get_fb_user_permissions: #{fe}"
        return nil
      end
    end
    return permissions   
  end 
  
  def get_fb_picture(id)
    graph = Koala::Facebook::GraphAPI.new
    return graph.get_picture(id, :type => "large")
  end
  
  def get_fb_object(id)
    graph = Koala::Facebook::GraphAPI.new
    return graph.get_object(id)
  end
  
  def parse_signed_request(signed_request)
    oauth = Koala::Facebook::OAuth.new(OPTIONS[:facebook_app_id], OPTIONS[:facebook_secret_key])
    results = oauth.parse_signed_request(signed_request)
    return results
  end
  
  # Test User methods

  # permissions should be a comma-separated string of facebook permissions
  def create_fb_test_user(connected=true,permissions="email")
    ug = Koala::Facebook::TestUsers.new(:app_id => OPTIONS[:facebook_app_id], :secret => OPTIONS[:facebook_secret_key])
    if connected
      user = ug.create(true, permissions)
    else
      user = ug.create(false)
    end
    return user
  end
  
  def delete_fb_test_user(user)
    ug = Koala::Facebook::TestUsers.new(:app_id => OPTIONS[:facebook_app_id], :secret => OPTIONS[:facebook_secret_key])
    ug.delete(user)    
    return true
  end 
  
  def delete_fb_test_users()
    ug = Koala::Facebook::TestUsers.new(:app_id => OPTIONS[:facebook_app_id], :secret => OPTIONS[:facebook_secret_key])
    ug.delete_all    
    return true
  end
  
end