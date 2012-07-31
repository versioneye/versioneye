
var winWidth = 950;
var winHeigh = 550;
var left = (screen.width/2)-(winWidth/2);
var top = (screen.height/2)-(winHeigh/2);

var fb_domainlink = "https://graph.facebook.com/oauth/authorize?";
var fb_req_perms = "req_perms=email&";
var fb_clientid = "client_id=230574627021570&";
var fb_scope = "scope=email,offline_access&";
var fb_redirect = "redirect_uri=https://www.versioneye.com/auth/facebook/callback";
var oauth_facebook_link = fb_domainlink + fb_req_perms + fb_clientid + fb_scope + fb_redirect;
var values = [{ label: "Choice1", va: "value1" }, { label: "Choice2", va: "value2" }]


jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});	
	
	jQuery('#fullname').tbHinter({
		text: "This is visible on your posts.",
		styleclass: "inputCelHint"
	});
	
	jQuery('#email').tbHinter({
		text: "Invisible for other users.",
		styleclass: "inputCelHint"
	});

	jQuery( "#tabs" ).tabs();

	if (window.FB){
		FB.init({
	        appId:'230574627021570', 
	        cookie:true,
	        status:true, 
	        xfbml:true
	    });	
	}

    jQuery("#ext_search_link").click(function() {
		jQuery("#extended_search_container").fadeToggle("slow", "linear");
	});

    map_for_jobs = document.getElementById("map_for_jobs")
    if (map_for_jobs){
    	initialize_jobs()	
    }

    map_for_profile = document.getElementById("map_for_user_profile")
    if (map_for_profile){
    	jQuery.ajax({
	        url: window.location.pathname + "/users_location.json"
	    }).done(function (data){
            if (data){
                initialize_profile(data.location);
            }
	    } );
    }

    if (window.render_wheel) {
    	render_wheel();
    }
    if (window.render_wheel_demo) {
    	render_wheel_demo();
    }
    if (window.render_wheel_main) {
    	render_wheel_main();
    }
    if (window.render_wheel_development) {
    	render_wheel_development();
    }
    if (window.render_wheel_test) {
    	render_wheel_test();
    }    
    if (window.render_wheel_provided) {
    	render_wheel_provided();
    }
    if (window.render_wheel_replace) {
    	render_wheel_replace();
    }
    if (window.render_wheel_require_dev) {
    	render_wheel_require_dev();
    }
});

function handle_path(options){
	jQuery.ajax({
        type: 'POST',
        url: "/package/image_path.json",
        data: { 'key': options.product_key, 'version': options.product_version, 'scope': options.scope },
        dataType: 'text',
        success: function(data) {
        	if (data == "nil" ){
        		upload_file(options);
        	} else {
        		show_pinit_button(data, options);
        	}
        }
    });
}

function upload_file(options){
	canvas = document.getElementById(options.canvas_id)
	if (canvas && options.pinit){
		jQuery.ajax({
	        type: 'POST',
	        url: "/package/upload_image.json",
	        data: { 'image': document.getElementById(options.canvas_id).toDataURL(), 'key': options.product_key, 'version': options.product_version, 'scope': options.scope },
	        dataType: 'text',
	        success: function(data) {
	            show_pinit_button(data, options);
	        }
	    });	
	}
}

function show_pinit_button(picture_url, options){
	if (options.pinit == false){
		return ;
	}
	if (options.resize == false && options.data_length > options.data_border){ 
		canvas_container = document.getElementById(options.container_id);
		var img = document.createElement("IMG");
		img.src = picture_url;
		img.style.width = "562px"
		canvas_container.appendChild(img);
	}
	pin_button = document.getElementById("pinit_" + options.scope);
	pin_button.href = "http://pinterest.com/pin/create/button/?url=https%3A%2F%2Fwww.versioneye.com/package/"+options.product_key+"/version/"+options.product_version+"&media="+picture_url+"&description=" + options.product_name + " : " + options.version + " : " + options.scope;
	pin_button.style.display = "block";
}


function load_dialog_follow(product_name){	
	document.getElementById('product_to_follow').innerHTML = product_name;	
	jQuery('#dialog_follow').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 600, 
		});	
}

function load_dialog_feedback(){	
	jQuery('#dialog_feedback').dialog(
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

function exchangeImage(id, image){
	image_path = "/assets/" + image
	document.getElementById(id).src=image_path;
}

function show_versioncomment_reply(id){
	var form_id = "#" + id + "_reply_form";
	var display_link = "#" + id + "_reply_link";
	var hide_link = "#" + id + "_hide_link";
	jQuery(form_id).css('display', 'block'); 
	jQuery(display_link).css('display', 'none'); 
	jQuery(hide_link).css('display', 'block'); 
	return false;
}

function hide_versioncomment_reply(id){
	var form_id = "#" + id + "_reply_form";
	var display_link = "#" + id + "_reply_link";
	var hide_link = "#" + id + "_hide_link";
	jQuery(form_id).css('display', 'none'); 
	jQuery(display_link).css('display', 'block'); 
	jQuery(hide_link).css('display', 'none'); 
	return false;
}

function shareOnFacebook(link, message){
	var picture = 'https://www.versioneye.com/assets/icon_114.png'
	FB.ui({ method: 'feed',
        link: link,
        picture: picture,
        description: message});
}

function fetchGitHubProjects(){
	fetchLinkArea = document.getElementById("fetchLinkArea");
	fetchLinkArea.style.display = "none";
	loadingbarArea = document.getElementById("loadingbarArea");
	loadingbarArea.style.display = "block";
	jQuery.ajax({
		url: "/user/projects/github_projects.json"
	}).done(function (data){
		if (data){
			addGitHubProjects(data)			
		}
	} );	
}

function addGitHubProjects(data){
	if (data[0].projects[0] == "BAD_CREDENTIALS"){
		alert("Your GitHub token is not valid anymore. Please login again with GitHub.")
		projectListArea = document.getElementById("gitHubLogin");
		projectListArea.style.display = "block";
	} else {
		for (i = 0; i < data[0].projects.length; i++ ){
			project = data[0].projects[i];
			var o = new Option(project, project);
			jQuery(o).html(project);
			jQuery("#github_projects").append(o);
		}
		projectListArea = document.getElementById("projectListArea");
		projectListArea.style.display = "block";
	}
	loadingbarArea = document.getElementById("loadingbarArea");
	loadingbarArea.style.display = "none";
}