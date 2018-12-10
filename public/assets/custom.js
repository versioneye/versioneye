
jQuery(document).ready(function(){

  console.log(" document loaded !")

  if (jQuery("#payment-form").length) {
    jQuery("#payment-form").submit( function(event) {
      var $form = jQuery("#payment-form");
      $form.find('button').prop('disabled', true);
      Stripe.card.createToken($form, stripeResponseHandler);
      // prevent the form from submitting with the default action
      return false;
    });
  }

  if(jQuery("#tabs").length > 0){
    jQuery( "#tabs" ).tabs();
  }

  if(jQuery("#inventory_diff_status").length > 0){
    // TODO
  }

  if(jQuery('.github_switch').length > 0){
    jQuery('.github_switch').on('switch-change', function(e, data){
      toggleGitHubProject(data.el, data.value);
    });
    console.log("Github switches are registered.");
  }

  if(jQuery('.btn-follow-product')){
    jQuery('.btn-follow-product').on('click', function(ev){
      toggleProductFollow(ev);
    });
  }

  if (jQuery('button[rel=tooltip]')){
    jQuery('button[rel=tooltip]').tooltip({ placement: 'bottom', html: true })
  }

  if (window.FB){
    FB.init({
          appId:'230574627021570',
          cookie:true,
          status:true,
          xfbml:true
      });
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

  if(jQuery(".btn-mute-version").length > 0){
    jQuery(".btn-mute-version").on("click", toggleProjectDependencyMute);
  }

  jcomment = jQuery('.user_comment')
  if (jcomment && jcomment.length > 0){
    jQuery('.user_comment').linkify();
  }
  jreply = jQuery('.versioncomment_reply_section')
  if (jreply && jreply.length > 0){
    jQuery('.versioncomment_reply_section').linkify()
  }

}); // end-of-ready

function stripeResponseHandler(status, response) {
  var $form = jQuery("#payment-form");
  if (response.error) {
    alert( response.error.message )
    // jQuery(".payment-errors").text(response.error.message);
    $form.find('button').prop('disabled', false);
  } else {
    var token = response.id; // token contains id, last4, and card type
    $form.append("<input type='hidden' name='stripeToken' value='" + token + "'/>");
    $form.get(0).submit();
  }
}

function confirmAction(){
  if (confirm('Are you sure?')){
    return true;
  } else {
    return false;
  }
}


function load_dialog_follow_delayed( product_name, prod_key, prod_lang ){
  setTimeout(function(){
    load_dialog_follow( product_name, prod_key, prod_lang );
  }, 2000);
}

function load_dialog_follow( product_name, prod_key, prod_lang ){
  document.getElementById('product_to_follow').innerHTML = product_name;
  setCookie( "prod_key" , prod_key,  1 );
  setCookie( "prod_lang", prod_lang, 1 )
  jQuery('#dialog_follow').modal({keyboard : true});
  page_view('ga_follow_dialog='+ prod_lang +'/'+ prod_key)
}

function toggleProductFollow(ev){
  var btn = jQuery(ev.currentTarget);
  var prod_info = btn.data();
  var follow_url = "/package/follow.json";
  var unfollow_url = "/package/unfollow.json";
  var api_url = follow_url;
  var on_icon = "fa fa-check-square-o";
  var off_icon = "fa fa-square-o";
  console.debug(prod_info);

  if(prod_info['followState'] == true){
    api_url = unfollow_url;
  }

  var dep_data = {
    src_hidden: "detail",
    product_lang: prod_info['productLang'],
    product_key: prod_info['productKey']
  }

  var onFollowSuccess = function(data){
    if(data.success == false){
      console.debug("Following failed - backend issue!");
      return 1;
    }
    console.debug("Followed:" + prod_info['productKey']);
    btn.data('followState', true);
    btn.find("span.btn-title").text(" Unfollow")
    btn.find("i.follow-icon")
        .removeClass(off_icon).addClass(on_icon);
  }
  var onUnfollowSuccess = function(data){
    if(data.success == false){
      console.debug("Unfollowing failed - backend issue!");
      return 1;
    }
    console.debug("Unfollowed:" + prod_info['productKey']);
    btn.data('followState', false);
    btn.find("i.follow-icon").removeClass(on_icon).addClass(off_icon);
    btn.find("span.btn-title").text(" Follow");
  }

  var showFollowLoader = function(){
    console.debug("Show follow  header");
    btn.find("i.follow-icon").addClass("fa fa-spinner");
  }
  var hideFollowLoader = function(){
    console.debug("Hide follow loader.");
    btn.find("i.follow-icon").removeClass("fa fa-spinner");
  }

  showFollowLoader();
  var jqxhr = jQuery.post(api_url, dep_data)
    .done(function(data){
      console.debug(data);
      if(prod_info['followState'] == false){
        onFollowSuccess(data);
      } else {
        onUnfollowSuccess(data);
      }
    })
    .fail(function(){console.error("Failed");})
    .always(function(){hideFollowLoader(btn);});
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

function setCookie(name, value, days){
  var date = new Date();
  new_date = new Date(date.getFullYear(), date.getMonth(), date.getDate()+days);
  document.cookie = name +"=" + value + ";expires=" + new_date + ";path=/";
}


function load_dialog_mute( button_id, dependency_name, dependency_version ){
  document.getElementById('mute_button_id').value = id;
  document.getElementById('mute_dependency_name').innerHTML = dependency_name;
  document.getElementById('mute_dependency_version').innerHTML = dependency_version;
  jQuery('#dialog_mute').modal({keyboard : true});
  page_view('ga_mute_dialog='+ dependency_name +'/'+ dependency_version)
}

function load_dialog_mute_security( project_id, sv_id, sv_name ) {
  document.getElementById('mute_sec_project_id').value = project_id;
  document.getElementById('mute_sec_id').value = sv_id;
  document.getElementById('mute_security_name').innerHTML = sv_name;
  jQuery('#dialog_mute_security').modal({keyboard : true});
  page_view('ga_mute_security_dialog='+ project_id +'/'+ sv_id)
}

function showMuteLoader(btn){
  console.debug("Loading");
  btn.addClass("disabled");
  btn.find("i.dep-icon").addClass("fa-spinner");
}

function hideMuteLoader(btn){
  console.debug("Hiding loader.");
  btn.removeClass("disabled");
  btn.find("i.dep-icon").removeClass("fa-spinner");
}

function muteProjectSec(){
  jQuery('#dialog_mute_security').modal("hide");
  mute_sec_project_id = document.getElementById('mute_sec_project_id').value
  mute_sec_id         = document.getElementById('mute_sec_id').value

  var message = document.getElementById('mute_sec_message').value
  var api_url = "/user/projects/mute_security";
  var dep_data = {
    "project_id": mute_sec_project_id,
    "sec_id": mute_sec_id,
    "mute_message": message
  };
  var jqxhr = jQuery.post(api_url, dep_data)
    .done(function(data){
      console.debug(data);
      location.reload();
    })
    .fail(function(){console.error("Failed");});
}

function muteProjectDep(){
  jQuery('#dialog_mute').modal("hide");
  id = document.getElementById('mute_button_id').value
  btn = jQuery(document.getElementById(id + "_button"));
  muteProjectDependency(btn);
}

function muteProjectDependency(btn){
  console.debug("Going to mute dependency.");
  showMuteLoader(btn);

  var message = document.getElementById('mute_message').value
  var api_url = "/user/projects/" + btn.data('projectId') + "/mute_dependency";
  var dep_data = {
    "dependency_id": btn.data('dependencyId'),
    "mute_message": message
  };
  var jqxhr = jQuery.post(api_url, dep_data)
    .done(function(data){
      console.debug(data);
      updateColorForPD( data.dependency_id, data.outdated )
      btn.removeClass("mute-off").addClass("mute-on");
      btn.find("i.dep-icon").removeClass("fa-volume-up").addClass("fa-volume-off");
    })
    .fail(function(){console.error("Failed");})
    .always(function(){hideMuteLoader(btn);});
}

function demuteProjectDependency(btn){
  console.debug("Going to de-mute dependency");
  showMuteLoader(btn);

  var api_url = "/user/projects/" + btn.data('projectId') + "/demute_dependency";
  var dep_data = {
    "dependency_id": btn.data('dependencyId')
  };
  var jqxhr = jQuery.post(api_url, dep_data)
    .done(function(data){
      console.debug(data);
      updateColorForPD( data.dependency_id, data.outdated )
      btn.removeClass("mute-on").addClass("mute-off");
      btn.find("i.dep-icon").removeClass("fa-volume-off").addClass("fa-volume-up")
    })
    .fail(function(){console.error("Failed");})
    .always(function(){hideMuteLoader(btn);});
}

function toggleProjectDependencyMute(ev){
  var btn = jQuery(ev.currentTarget);

  if(btn.hasClass("disabled")){
    console.debug("Going to ignore: Click on disabled button");
  } else if(btn.hasClass("mute-on")){
    demuteProjectDependency(btn);
  } else if(btn.hasClass("mute-off")){
    // muteProjectDependency(btn);
    id      = btn.data('id')
    name    = btn.data('dependency-name')
    version = btn.data('dependency-version')
    load_dialog_mute(id, name, version);
  } else {
    console.debug("Hmm, mute button misses classes. Going to ignore that");
  }

  return false;
}

function updateColorForPD(projectdependency_id, outdated){
  rows = jQuery("#" + projectdependency_id + "__row")
  if (outdated == true){
    rows[0].className = "flash error"
  } else {
    rows[0].className = "flash success"
  }
}


function preventSubmit(id, name){
  element = document.getElementById(id)
  if (element.value == ""){
    alert("The " + name + " input field can't be empty!")
    return false;
  }
  return true;
}
