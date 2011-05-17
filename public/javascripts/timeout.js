function format(seconds, div, mod) {
  	s = ((Math.floor(seconds/div))%mod).toString();
	if (s.length < 2)
    	s = "0" + s;
  	return "<b>" + s + "</b>";
}

function TimeOut(seconds) {
	if (seconds < 0) {
		window.location.reload(true)
    	return;
	}
	Message = "You have %M:%S to complete your order."
  	Message = Message.replace(/%M/g, format(seconds,60,60));
  	Message = Message.replace(/%S/g, format(seconds,1,60));

  	document.getElementById("timeout").innerHTML = Message;
  	setTimeout("TimeOut(" + (seconds-1) + ")", 1000);
}
