/* 
 * jQuery - Textbox Hinter plugin v1.0
 * http://www.aakashweb.com/
 * Copyright 2010, Aakash Chakravarthy
 * Released under the MIT License.
 */
!function(t){t.fn.tbHinter=function(e){var n={text:"Enter a text ...",styleclass:""},e=t.extend(n,e);return this.each(function(){t(this).focus(function(){t(this).val()==e.text&&(t(this).val(""),t(this).removeClass(e.styleclass))}),t(this).blur(function(){""==t(this).val()&&(t(this).val(e.text),t(this).addClass(e.styleclass))}),t(this).blur()})}}(jQuery);