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
		item.addEvent("click", function(e) {
			
			new Event(e).stop();
			
			new Request({
				method: 'post',
				url : create_share_url,
				data : {'deal_id' : deal.id},
				onSuccess : function(response_text, response_xml) {
					//console.log(response_text)
					var d = JSON.decode(response_text);
					//console.log(d);
					if(d && d.result == "success" && d.update_share_url) {
						facebook_share(d.update_share_url);
					}
				}
			}).send();
		});
	});
};

var facebook_share = function(update_share_url) {
	FB.ui({
		method: 'feed',
       	name: deal.name,
       	caption: deal.caption,
		description: deal.description,
		picture: deal.picture,
		link: deal.url,
     	actions: [{ name: 'Check it out!', link: deal.url }]
		},
		function (response) {
			if (response && response.post_id) {
				complete_share(update_share_url, response.post_id);
			}
		}
	);			
}

var complete_share = function(update_share_url, post_id) {
	new Request({
		method: 'post',
		url : update_share_url,
		data : {'post_id' : post_id},
		onSuccess : function(response_text, response_xml) {
			alert('Thank you for sharing!') }
	}).send();
}

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

var onload_payment_receipt = function() {
	add_share_events();	
};

var onload_facebook_payment_receipt = function() {
	add_share_events();	
};