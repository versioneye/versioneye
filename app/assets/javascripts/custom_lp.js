
jQuery(document).ready(function() {

	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});

});

function regulate_height(){
  myHeight = window.innerHeight;
  if (myHeight > 410) {
    padding_height = myHeight - 428;
    reasons_height = (myHeight - 482) / 2;
    features_height = (myHeight - 500) / 2;
    document.getElementById("search_section").style.cssText = "padding-bottom: " + padding_height + "px;";
    document.getElementById("reasons").style.cssText = "padding-top: " + reasons_height + "px; padding-bottom: " + reasons_height +"px;";
    document.getElementById("features").style.cssText = "padding-top: " + features_height + "px; padding-bottom: " + features_height +"px;";
  } else {
    document.getElementById("search_section").style.cssText = "padding-bottom: 65px";
  }
  setTimeout( function(){ regulate_height() }  , 1000 );
}
