// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
window.addEvent('domready', function() {

	// Call functions that may be included in multiple pages.. TODO: rethink this..
	//common_functions();

	// Dom ready code that is generically run on every page	
	var body = $(document.body);
	
	if(body && body.id) {
		
		var name = "onload_" + body.id;
		
		if(window[name] && $type(window[name]) == "function") window[name]();	
	}	
});