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
	// If they are already logged in - redirect_to :connect button
	// Else - show fb:login-button	
	FB.getLoginStatus(function(response) {
		if (response.status == 'connected') {
			document.getElementById('fb-login-button').innerHTML = facebook_login_button;
		} 
		else { 
			document.getElementById('fb-login-button').innerHTML = '<fb:login-button id="facebook-login-button" perms="email">Login</fb:login-button>';
			FB.XFBML.parse(document.getElementById('fb-login-button'));
		}
	});
}

var add_publish_stream = function() {
	// Hack around FB SSL bug (http://bugs.developers.facebook.net/show_bug.cgi?id=17121)
	if(document.location.protocol == 'https:' && !!FB && !!FB._domain && !!FB._domain.staticfb) {
		FB._domain.staticfb = FB._domain.staticfb.replace('http://static.ak.facebook.com/', 'https://s-static.ak.fbcdn.net/');
	}
	// Always show fb:login-button	
	FB.getLoginStatus(function(response) {
		document.getElementById('fb-login-button').innerHTML = 
		'<fb:login-button id="facebook-login-button" perms="email,publish_stream" onLogin="goto_url(\'' + connect_url + '\')">Login</fb:login-button>';
		FB.XFBML.parse(document.getElementById('fb-login-button'));
	});
}

var goto_url = function(url) {
	window.location = url;
}

//Fb_share methods
var set_friend_selector = function(facebook_id, parent_element) {
	console.log(facebook_id)
	console.log(parent_element)
	var spinner = new Spinner(parent_element, {
		message : "Loading your friends..."
	});
	spinner.show();

	var url = "/friends";

	FB.api(facebook_id + url, function(response) {
		//console.log(response)
		// Sort em
		var friends = response.data.sort(function(a,b) {
			a = a["name"].toLowerCase();
			b = b["name"].toLowerCase();
			if(a > b){
				return 1;
			} else if(a < b) {
				return -1;
			} else {
				return 0;
			}
		});		
		
		//console.log(friends)
		var html = get_friend_selector(friends);
		//console.log(html)
		// Inject into parent
		// TODO: make this optional?
		//console.log($(parent_element))
		//console.log(document.getElementById(parent_element))
		html.inject(document.getElementById(parent_element));
		spinner.hide();
	});
};

var get_friend_selector = function(friends, params) {
	// Get the friend selector html from a list of friend objects [{id : "1", name : "foo bar"}]
	
	// Setup defaults
	if(params == undefined) params = {};
	var max_friends = params["max_friends"] || 25;
			
	// Get the template
	var template = new EJS({url: '/javascripts/templates/friends.ejs'});
	html_string = template.render({ friends : friends });
			
	// Convert to html elements
	var html = Elements.from(html_string);

	if(html.length == 0) throw Exception("Invalid html elements from friend template");
	
	var friend_selector = html[0];
				
	// TODO: This is ghetto. For some reason getElementById or getElement aren't working
	var dom_items = friend_selector.getChildren(); // Top element
	//console.log(dom_items)
	var friend_count = dom_items[1].getElement("SPAN"); // Friend count section
	
	// Iterate over all friends LI objects and add click actions
	dom_items[2].getElements('LI').each(function(item) {
		
		item.addEvent("click", function(e) {
		
			var selected = item.hasClass("selected");
			var cb = item.getElement("INPUT");
			var count = friend_count.get("html").toInt();

			// Toggle the checkbox value, change the count, and toggle the selected class
			cb.set("checked", !selected);
			selected ? friend_count.set("html", count -= 1) : friend_count.set("html", count += 1);
			item.toggleClass("selected");
		});
		
	});
	
	return friend_selector;
};

/*
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
*/

var add_incentive_disabling = function() {
	document.getElementById('incentive_type').addEvent("change",
		function(e) {
			if (e.target.value == "") {
		    	document.getElementById('incentive').hide();
			}
			else {
				document.getElementById('incentive').show();
			}
	    }
	);
}

var onload_user_login = function() {
	facebook_login();
};

var onload_facebook_login = function() {
	facebook_login();
};

/*
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
*/

var onload_merchant_new_deal = function() {
	add_incentive_disabling();
}

var onload_merchant_create_deal = function() {
	add_incentive_disabling();
}

var onload_merchant_edit_deal = function() {
	add_incentive_disabling();
}

var onload_merchant_update_deal = function() {
	add_incentive_disabling();
}

var onload_user_confirm_permissions = function() {
	add_publish_stream();
}

var onload_facebook_confirm_permissions = function() {
	add_publish_stream();
}

var onload_user_fb_share = function() {
	set_friend_selector(fb_id, "friend_selector_container");
}

var onload_facebook_fb_share = function() {
	set_friend_selector(fb_id, "friend_selector_container");
}
