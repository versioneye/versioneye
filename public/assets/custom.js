function stripeResponseHandler(e,t){if(t.error)alert(t.error.message),$(".payment-errors").text(t.error.message),jQuery(".submit-button").removeAttr("disabled");else{var n=jQuery("#payment-form"),i=t.id;n.append("<input type='hidden' name='stripeToken' value='"+i+"'/>"),n.get(0).submit()}}function confirmAction(){return confirm("Are you sure?")?!0:!1}function load_dialog_follow(e,t,n){document.getElementById("product_to_follow").innerHTML=e,setCookie("prod_key",t,1),setCookie("prod_lang",n,1),jQuery("#dialog_follow").modal({keyboard:!0}),page_view("ga_follow_dialog="+n+"/"+t)}function toggleProductFollow(e){var t=jQuery(e.currentTarget),n=t.data(),i="/package/follow.json",r="/package/unfollow.json",o=i,s="icon-check",a="icon-check-empty";console.debug(n),1==n.followState&&(o=r);var u={src_hidden:"detail",product_lang:n.productLang,product_key:n.productKey},l=function(e){return 0==e.success?(console.debug("Following failed - backend issue!"),1):(console.debug("Followed:"+n.productKey),t.data("followState",!0),t.find("span.btn-title").text(" Unfollow"),void t.find("i.follow-icon").removeClass(a).addClass(s))},c=function(e){return 0==e.success?(console.debug("Unfollowing failed - backend issue!"),1):(console.debug("Unfollowed:"+n.productKey),t.data("followState",!1),t.find("i.follow-icon").removeClass(s).addClass(a),void t.find("span.btn-title").text(" Follow"))},d=function(){console.debug("Show follow  header"),t.find("i.follow-icon").addClass("icon-spin")},f=function(){console.debug("Hide follow loader."),t.find("i.follow-icon").removeClass("icon-spin")};d();jQuery.post(o,u).done(function(e){console.debug(e),0==n.followState?l(e):c(e)}).fail(function(){console.error("Failed")}).always(function(){f(t)})}function exchangeImage(e,t){image_path="/assets/"+t,document.getElementById(e).src=image_path}function show_versioncomment_reply(e){var t="#"+e+"_reply_form",n="#"+e+"_reply_link",i="#"+e+"_hide_link";return jQuery(t).css("display","block"),jQuery(n).css("display","none"),jQuery(i).css("display","block"),!1}function hide_versioncomment_reply(e){var t="#"+e+"_reply_form",n="#"+e+"_reply_link",i="#"+e+"_hide_link";return jQuery(t).css("display","none"),jQuery(n).css("display","block"),jQuery(i).css("display","none"),!1}function setCookie(e,t,n){var i=new Date;new_date=new Date(i.getFullYear(),i.getMonth(),i.getDate()+n),document.cookie=e+"="+t+";expires="+new_date+";path=/"}function showMuteLoader(e){console.debug("Loading"),e.addClass("disabled"),e.find("i.dep-icon").addClass("icon-spin")}function hideMuteLoader(e){console.debug("Hiding loader."),e.removeClass("disabled"),e.find("i.dep-icon").removeClass("icon-spin")}function muteProjectDependency(e){console.debug("Going to mute dependency."),showMuteLoader(e);{var t="/user/projects/"+e.data("projectId")+"/mute_dependency",n={dependency_id:e.data("dependencyId")};jQuery.post(t,n).done(function(t){console.debug(t),updateColorForPD(t.dependency_id,t.outdated),e.removeClass("mute-off").addClass("mute-on"),e.find("i.dep-icon").removeClass("icon-volume-up").addClass("icon-volume-off")}).fail(function(){console.error("Failed")}).always(function(){hideMuteLoader(e)})}}function demuteProjectDependency(e){console.debug("Going to de-mute dependency"),showMuteLoader(e);{var t="/user/projects/"+e.data("projectId")+"/demute_dependency",n={dependency_id:e.data("dependencyId")};jQuery.post(t,n).done(function(t){console.debug(t),updateColorForPD(t.dependency_id,t.outdated),e.removeClass("mute-on").addClass("mute-off"),e.find("i.dep-icon").removeClass("icon-volume-off").addClass("icon-volume-up")}).fail(function(){console.error("Failed")}).always(function(){hideMuteLoader(e)})}}function toggleProjectDependencyMute(e){var t=jQuery(e.currentTarget);return t.hasClass("disabled")?console.debug("Going to ignore: Click on disabled button"):t.hasClass("mute-on")?demuteProjectDependency(t):t.hasClass("mute-off")?muteProjectDependency(t):console.debug("Hmm, mute button misses classes. Going to ignore that"),!1}function updateColorForPD(e,t){rows=jQuery("#"+e+"__row"),rows[0].className=1==t?"flash error":"flash success"}function preventSubmit(e,t){return element=document.getElementById(e),""==element.value?(alert("The "+t+" input field can't be empty!"),!1):!0}jQuery(document).ready(function(){jQuery("#q").tbHinter({text:"Search for a software library"}),jQuery("#ext_searchform").submit(function(){"Search for a software library"==document.getElementById("q").value&&(document.getElementById("q").value="")}),jQuery("#payment-form").length&&jQuery("#payment-form").submit(function(){return jQuery(".submit-button").attr("disabled","disabled"),Stripe.createToken({number:jQuery(".card-number").val(),cvc:jQuery(".card-cvc").val(),exp_month:jQuery(".card-expiry-month").val(),exp_year:jQuery(".card-expiry-year").val()},stripeResponseHandler),!1}),jQuery("#tabs").length>0&&jQuery("#tabs").tabs(),jQuery(".github_switch").length>0&&(jQuery(".github_switch").on("switch-change",function(e,t){toggleGitHubProject(t.el,t.value)}),console.log("Github switches are registered.")),jQuery(".btn-follow-product")&&jQuery(".btn-follow-product").on("click",function(e){toggleProductFollow(e)}),window.FB&&FB.init({appId:"230574627021570",cookie:!0,status:!0,xfbml:!0}),map_for_profile=document.getElementById("map_for_user_profile"),map_for_profile&&(path=window.location.pathname,path=path.replace("/favoritepackages",""),path=path.replace("/comments",""),jQuery.ajax({url:path+"/users_location.json"}).done(function(e){e&&initialize_profile(e.location)})),window.render_wheel&&render_wheel(),window.render_wheel_demo&&render_wheel_demo(),window.render_wheel_main&&render_wheel_main(),window.render_wheel_development&&render_wheel_development(),window.render_wheel_test&&render_wheel_test(),window.render_wheel_provided&&render_wheel_provided(),window.render_wheel_replace&&render_wheel_replace(),window.render_wheel_require_dev&&render_wheel_require_dev(),jQuery(".btn-mute-version").length>0&&jQuery(".btn-mute-version").on("click",toggleProjectDependencyMute)});