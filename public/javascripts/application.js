// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var facebook_login = function() {
	// Hack around FB SSL bug (http://bugs.developers.facebook.net/show_bug.cgi?id=17121)
	if(document.location.protocol == 'https:' && !!FB && !!FB._domain && !!FB._domain.staticfb) {
		FB._domain.staticfb = FB._domain.staticfb.replace('http://static.ak.facebook.com/', 'https://s-static.ak.fbcdn.net/');
	}
	// If they log in - redirect_to :connect
	FB.Event.subscribe('auth.login', function() {
		window.location = connect_url;
	});
	// If they are already logged in - redirect_to :connect
	// Else - show fb:login-button 
	FB.getLoginStatus(function(response) {
		if (response.status == 'connected') {
			document.getElementById('fb-login-button').innerHTML = facebook_login_button;
		} 
		else { 
			document.getElementById('fb-login-button').innerHTML = '<fb:login-button perms="email">Login</fb:login-button>';
			FB.XFBML.parse(document.getElementById('fb-login-button'));
		}
	});
}

var add_share_events = function() {	
	$$(".facebook").each(function(item) {
	
		item.addEvent("click", function() {
			
			var share_link = this;
			
			FB.ui({
				method: 'stream.publish',
		     	message: deal.message,
				attachment: {
		       		name: deal.name,
		       		caption: deal.caption,
					media : [{ 
					        type : "image", 
					        src : deal.picture,
							href : deal.attribution
					}]
		     	},
		     	action_links: [{ 
					text: 'Check it out!', href : deal.attribution 
				}],
				user_message_prompt: 'Share this Deal!'
		   	});
		});
	});
};

var onload_user_login = function() {
	facebook_login();
};

var onload_facebook_login = function() {
	facebook_login();
};

var onload_user_deal = function() {
	add_share_events();
};

var onload_facebook_deal = function() {
	add_share_events();
};
