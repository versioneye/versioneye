jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});


  if (jQuery('.fb_math').length){
     render_captcha_math()      
  }

	
});


function load_video(){
  jQuery('#dialog_video').modal({keyboard : true});
}


function render_captcha_math(){
	value_a = Math.floor((Math.random()*10)+1);
	value_b = Math.floor((Math.random()*10)+1);
	jQuery("[name='value_a']").val(value_a);
	jQuery("[name='value_b']").val(value_b);
	fb_math_label = jQuery(".fb_math");
	fb_math_label.html(value_a + " + " + value_b + " = ");
}


