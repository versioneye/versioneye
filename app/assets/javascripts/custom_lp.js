jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});
	
});

function load_video(){
  jQuery('#dialog_video').modal({keyboard : true});
}
