/* 
 * jQuery - Textbox Hinter plugin v1.0
 * http://www.aakashweb.com/
 * Copyright 2010, Aakash Chakravarthy
 * Released under the MIT License.
 */

(function($){
	$.fn.tbHinter = function(options) {

	var defaults = {
		text: 'Enter a text ...',
   		class: ''
	};
	
	var options = $.extend(defaults, options);

	return this.each(function(){
	
		$(this).focus(function(){
			if($(this).val() == options.text){
				$(this).val('');
				$(this).removeClass(options.class);
			}
		});
		
		$(this).blur(function(){
			if($(this).val() == ''){
				$(this).val(options.text);
				$(this).addClass(options.class);
			}
		});
		
		$(this).blur();
		
	});
};
})(jQuery);