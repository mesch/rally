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
  
  def get_fb_picture(id)
    graph = Koala::Facebook::GraphAPI.new
    return graph.get_picture(id, :type => "large")
  end
  
  def parse_signed_request(signed_request)
    oauth = Koala::Facebook::OAuth.new(OPTIONS[:facebook_app_id], OPTIONS[:facebook_secret_key])
    results = oauth.parse_signed_request(signed_request)
    return results
  end
  
end