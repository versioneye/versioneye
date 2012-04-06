
var winWidth = 950;
var winHeigh = 550;
var left = (screen.width/2)-(winWidth/2);
var top = (screen.height/2)-(winHeigh/2);

var fb_domainlink = "https://graph.facebook.com/oauth/authorize?";
var fb_req_perms = "req_perms=email&";
var fb_clientid = "client_id=230574627021570&";
var fb_scope = "scope=email,offline_access&";
var fb_redirect = "redirect_uri=http://versioneye.com/auth/facebook/callback";
var oauth_facebook_link = fb_domainlink + fb_req_perms + fb_clientid + fb_scope + fb_redirect;

$(document).ready(function() {
	
	$('#q').tbHinter({
		text: "xpath",
		styleclass: "lp_searchfield_hint"
	});	
	
	$('#fullname').tbHinter({
		text: "This is visible on your posts.",
		styleclass: "inputCelHint"
	});
	
	$('#email').tbHinter({
		text: "Invisible for other users.",
		styleclass: "inputCelHint"
	});

	FB.init({
        appId:'230574627021570', cookie:true,
        status:true, xfbml:true
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

function load_dialog_feedback(){	
	$('#dialog_feedback').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 700, 
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

function validateFeedbackForm(){	
	var result = true
	var fullname = document.getElementById('fb_fullname').value;	
	if (fullname == "" || fullname == null){
		alert('Please type in your Name.')
		result = false
	}
	var email = document.getElementById('fb_email').value;	
	result = validateEmail(email)
	var feedback = document.getElementById('feedback').value;	
	if (feedback == "" || feedback == null){
		alert('Please type in your Feedback.')
		result = false
	}
}

function textCounter(field, cntfield, maxlimit) {
	if (field.value.length > maxlimit) 
		field.value = field.value.substring(0, maxlimit);
	else
		cntfield.innerHTML = maxlimit - field.value.length;
}

function shareOnFacebook(link, message){
	var picture = 'http://versioneye.com/assets/icon_114.png'
	FB.ui({ method: 'feed',
        link: link,
        picture: picture,
        description: message});
}