/* 
 * jQuery - Textbox Hinter plugin v1.0
 * http://www.aakashweb.com/
 * Copyright 2010, Aakash Chakravarthy
 * Released under the MIT License.
 */
(function(a){a.fn.tbHinter=function(b){var c={text:"Enter a text ...",styleclass:""},b=a.extend(c,b);return this.each(function(){a(this).focus(function(){a(this).val()==b.text&&(a(this).val(""),a(this).removeClass(b.styleclass))}),a(this).blur(function(){a(this).val()==""&&(a(this).val(b.text),a(this).addClass(b.styleclass))}),a(this).blur()})}})(jQuery)