module Facebook

  def get_fb_user
    oauth = Koala::Facebook::OAuth.new(OPTIONS[:facebook_app_id], OPTIONS[:facebook_secret_key])
    p oauth
    user_info = oauth.get_user_info_from_cookies(cookies)
    p user_info
    if user_info && user_info["access_token"] && user_info["uid"]
      graph = Koala::Facebook::GraphAPI.new(user_info["access_token"])
      p graph
      fb_user = graph.get_object(user_info["uid"])
      p fb_user
    end
    return fb_user
  end
  
  def get_fb_picture(id)
    graph = Koala::Facebook::GraphAPI.new
    return graph.get_picture(id, :type => "large")
  end
  
end