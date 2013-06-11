
jQuery(document).ready(function() {

	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});

});

function load_video(){
  jQuery('#dialog_video').modal({keyboard : true});
}

function regulate_height(){
  myHeight = window.innerHeight;
  if (myHeight > 410) {
    padding_height = myHeight - 419;
    document.getElementById("search_section").style.cssText = "padding-bottom: " + padding_height + "px;";
  } else {
    document.getElementById("search_section").style.cssText = "padding-bottom: 65px";
  }
  setTimeout( function(){ regulate_height() }  , 1000 );
}
