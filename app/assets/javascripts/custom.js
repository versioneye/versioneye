
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

jQuery(document).ready(function(){
  jQuery('#q').tbHinter({
    text: "json",
    styleclass: "lp_searchfield_hint"
  });

  if(jQuery("#payment-form").length){
    jQuery("#payment-form").submit( function(event) {
      jQuery('.submit-button').attr("disabled", "disabled");
      Stripe.createToken({
          number: jQuery('.card-number').val(),
          cvc: jQuery('.card-cvc').val(),
          exp_month: jQuery('.card-expiry-month').val(),
          exp_year: jQuery('.card-expiry-year').val()
      }, stripeResponseHandler);
      // prevent the form from submitting with the default action
      return false;
    });
  }

  if(jQuery("#tabs").length > 0){
    jQuery( "#tabs" ).tabs();
  }

  if(jQuery('.github_switch').length > 0){
    jQuery('.github_switch').on('switch-change', function(e, data){
      toggleGitHubProject(data.el, data.value);
    });
    console.log("Github switches are registered.");
  }

  if (window.FB){
    FB.init({
          appId:'230574627021570',
          cookie:true,
          status:true,
          xfbml:true
      });
  }

  map_for_jobs = document.getElementById("map_for_jobs")
  if (map_for_jobs){
    initialize_jobs()
  }

  map_for_profile = document.getElementById("map_for_user_profile")
  if (map_for_profile){
    path = window.location.pathname;
    path = path.replace("/favoritepackages", "")
    path = path.replace("/comments", "")
    jQuery.ajax({
        url: path + "/users_location.json"
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
}); // end-of-ready

function stripeResponseHandler(status, response) {
  if (response.error) {
    alert(response.error.message)
    // show the errors on the form
    $(".payment-errors").text(response.error.message);
    jQuery(".submit-button").removeAttr("disabled");
  } else {
    var form$ = jQuery("#payment-form");
    // token contains id, last4, and card type
    var token = response['id'];
    // insert the token into the form so it gets submitted to the server
    form$.append("<input type='hidden' name='stripeToken' value='" + token + "'/>");
    // and submit
    form$.get(0).submit();
  }
}

function confirmAction(){
  if (confirm('Are you sure?')){
    return true;
  } else {
    return false;
  }
}

function load_dialog_follow(product_name, prod_key){
  document.getElementById('product_to_follow').innerHTML = product_name;
  setCookie("prod_key", prod_key, 1);
  jQuery('#dialog_follow').modal({keyboard : true});
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

function setCookie(name, value, days){
  var date = new Date();
  new_date = new Date(date.getFullYear(), date.getMonth(), date.getDate()+days);
  document.cookie = name +"=" + value + ";expires=" + new_date + ";path=/";
}
