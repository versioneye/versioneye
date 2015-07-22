/*!
 * Jasny Bootstrap v3.1.3 (http://jasny.github.io/bootstrap)
 * Copyright 2012-2014 Arnold Daniels
 * Licensed under Apache-2.0 (https://github.com/jasny/bootstrap/blob/master/LICENSE)
 */
if("undefined"==typeof jQuery)throw new Error("Jasny Bootstrap's JavaScript requires jQuery");/* ========================================================================
 * Bootstrap: transition.js v3.1.3
 * http://getbootstrap.com/javascript/#transitions
 * ========================================================================
 * Copyright 2011-2014 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */
/* ===========================================================
 * Bootstrap: fileinput.js v3.1.3
 * http://jasny.github.com/bootstrap/javascript/#fileinput
 * ===========================================================
 * Copyright 2012-2014 Arnold Daniels
 *
 * Licensed under the Apache License, Version 2.0 (the "License")
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */
+function(e){"use strict";var t="Microsoft Internet Explorer"==window.navigator.appName,n=function(t,n){if(this.$element=e(t),this.$input=this.$element.find(":file"),0!==this.$input.length){this.name=this.$input.attr("name")||n.name,this.$hidden=this.$element.find('input[type=hidden][name="'+this.name+'"]'),0===this.$hidden.length&&(this.$hidden=e('<input type="hidden">').insertBefore(this.$input)),this.$preview=this.$element.find(".fileinput-preview");var i=this.$preview.css("height");"inline"!==this.$preview.css("display")&&"0px"!==i&&"none"!==i&&this.$preview.css("line-height",i),this.original={exists:this.$element.hasClass("fileinput-exists"),preview:this.$preview.html(),hiddenVal:this.$hidden.val()},this.listen()}};n.prototype.listen=function(){this.$input.on("change.bs.fileinput",e.proxy(this.change,this)),e(this.$input[0].form).on("reset.bs.fileinput",e.proxy(this.reset,this)),this.$element.find('[data-trigger="fileinput"]').on("click.bs.fileinput",e.proxy(this.trigger,this)),this.$element.find('[data-dismiss="fileinput"]').on("click.bs.fileinput",e.proxy(this.clear,this))},n.prototype.change=function(t){var n=void 0===t.target.files?t.target&&t.target.value?[{name:t.target.value.replace(/^.+\\/,"")}]:[]:t.target.files;if(t.stopPropagation(),0===n.length)return void this.clear();this.$hidden.val(""),this.$hidden.attr("name",""),this.$input.attr("name",this.name);var i=n[0];if(this.$preview.length>0&&("undefined"!=typeof i.type?i.type.match(/^image\/(gif|png|jpeg)$/):i.name.match(/\.(gif|png|jpe?g)$/i))&&"undefined"!=typeof FileReader){var r=new FileReader,o=this.$preview,s=this.$element;r.onload=function(t){var r=e("<img>");r[0].src=t.target.result,n[0].result=t.target.result,s.find(".fileinput-filename").text(i.name),"none"!=o.css("max-height")&&r.css("max-height",parseInt(o.css("max-height"),10)-parseInt(o.css("padding-top"),10)-parseInt(o.css("padding-bottom"),10)-parseInt(o.css("border-top"),10)-parseInt(o.css("border-bottom"),10)),o.html(r),s.addClass("fileinput-exists").removeClass("fileinput-new"),s.trigger("change.bs.fileinput",n)},r.readAsDataURL(i)}else this.$element.find(".fileinput-filename").text(i.name),this.$preview.text(i.name),this.$element.addClass("fileinput-exists").removeClass("fileinput-new"),this.$element.trigger("change.bs.fileinput")},n.prototype.clear=function(e){if(e&&e.preventDefault(),this.$hidden.val(""),this.$hidden.attr("name",this.name),this.$input.attr("name",""),t){var n=this.$input.clone(!0);this.$input.after(n),this.$input.remove(),this.$input=n}else this.$input.val("");this.$preview.html(""),this.$element.find(".fileinput-filename").text(""),this.$element.addClass("fileinput-new").removeClass("fileinput-exists"),void 0!==e&&(this.$input.trigger("change"),this.$element.trigger("clear.bs.fileinput"))},n.prototype.reset=function(){this.clear(),this.$hidden.val(this.original.hiddenVal),this.$preview.html(this.original.preview),this.$element.find(".fileinput-filename").text(""),this.original.exists?this.$element.addClass("fileinput-exists").removeClass("fileinput-new"):this.$element.addClass("fileinput-new").removeClass("fileinput-exists"),this.$element.trigger("reset.bs.fileinput")},n.prototype.trigger=function(e){this.$input.trigger("click"),e.preventDefault()};var i=e.fn.fileinput;e.fn.fileinput=function(t){return this.each(function(){var i=e(this),r=i.data("bs.fileinput");r||i.data("bs.fileinput",r=new n(this,t)),"string"==typeof t&&r[t]()})},e.fn.fileinput.Constructor=n,e.fn.fileinput.noConflict=function(){return e.fn.fileinput=i,this},e(document).on("click.fileinput.data-api",'[data-provides="fileinput"]',function(t){var n=e(this);if(!n.data("bs.fileinput")){n.fileinput(n.data());var i=e(t.target).closest('[data-dismiss="fileinput"],[data-trigger="fileinput"]');i.length>0&&(t.preventDefault(),i.trigger("click.bs.fileinput"))}})}(window.jQuery);