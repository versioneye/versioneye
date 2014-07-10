/* 
 * jQuery - Textbox Hinter plugin v1.0
 * http://www.aakashweb.com/
 * Copyright 2010, Aakash Chakravarthy
 * Released under the MIT License.
 */
!function(e){e.fn.tbHinter=function(t){var n={text:"Enter a text ...",styleclass:""},t=e.extend(n,t);return this.each(function(){e(this).focus(function(){e(this).val()==t.text&&(e(this).val(""),e(this).removeClass(t.styleclass))}),e(this).blur(function(){""==e(this).val()&&(e(this).val(t.text),e(this).addClass(t.styleclass))}),e(this).blur()})}}(jQuery);