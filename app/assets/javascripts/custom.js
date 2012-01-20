
var winWidth = 950;
var winHeigh = 550;
var left = (screen.width/2)-(winWidth/2);
var top = (screen.height/2)-(winHeigh/2);

var domainlink = "https://graph.facebook.com/oauth/authorize?";
var req_perms = "req_perms=email&";
var clientid = "client_id=230574627021570&";
var scope = "scope=email,offline_access&";
var redirect = "redirect_uri=http://versioneye-beta.com/facebook/start";
var link = domainlink + req_perms + clientid + scope + redirect;

$(document).ready(function() {
	
	$('#q').tbHinter({
		text: "Be up-to-date",
		styleclass: "searchfield_hint"
	});	
	
	$('#fullname').tbHinter({
		text: "This is visible on your posts.",
		styleclass: "inputCelHint"
	});

	$('#username').tbHinter({
		text: "/users/USERNAME",
		styleclass: "inputCelHint"
	});
	
	$('#email').tbHinter({
		text: "Invisible for other users.",
		styleclass: "inputCelHint"
	});
	
	$('#password').tbHinter({
		text: "Your secret.",
		styleclass: "inputCelHint"
	});
	
	
});

function load_dialog_follow(product_name){	
	document.getElementById('product_to_follow').innerHTML = product_name;	
	$('#dialog_follow').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 600, 
		});	
}

function validateEmail(elementValue){  
	var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;  
	var result = emailPattern.test(elementValue);  
	if (result == false){
		alert('The E-Mail Address is not valid! Please type in a valid E-Mail Address');
	}
	return result;
}

function textCounter(field, cntfield, maxlimit) {
	if (field.value.length > maxlimit) 
		field.value = field.value.substring(0, maxlimit);
	else
		cntfield.innerHTML = maxlimit - field.value.length;
}