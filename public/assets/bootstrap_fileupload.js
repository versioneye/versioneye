/* ===========================================================
 * bootstrap-fileupload.js j2
 * http://jasny.github.com/bootstrap/javascript.html#fileupload
 * ===========================================================
 * Copyright 2012 Jasny BV, Netherlands.
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
!function(e){"use strict";var t=function(t,n){if(this.$element=e(t),this.type=this.$element.data("uploadtype")||(this.$element.find(".thumbnail").length>0?"image":"file"),this.$input=this.$element.find(":file"),0!==this.$input.length){this.name=this.$input.attr("name")||n.name,this.$hidden=this.$element.find('input[type=hidden][name="'+this.name+'"]'),0===this.$hidden.length&&(this.$hidden=e('<input type="hidden" />'),this.$element.prepend(this.$hidden)),this.$preview=this.$element.find(".fileupload-preview");var i=this.$preview.css("height");"inline"!=this.$preview.css("display")&&"0px"!=i&&"none"!=i&&this.$preview.css("line-height",i),this.original={exists:this.$element.hasClass("fileupload-exists"),preview:this.$preview.html(),hiddenVal:this.$hidden.val()},this.$remove=this.$element.find('[data-dismiss="fileupload"]'),this.$element.find('[data-trigger="fileupload"]').on("click.fileupload",e.proxy(this.trigger,this)),this.listen()}};t.prototype={listen:function(){this.$input.on("change.fileupload",e.proxy(this.change,this)),e(this.$input[0].form).on("reset.fileupload",e.proxy(this.reset,this)),this.$remove&&this.$remove.on("click.fileupload",e.proxy(this.clear,this))},change:function(e,t){if("clear"!==t){var n=void 0!==e.target.files?e.target.files[0]:e.target.value?{name:e.target.value.replace(/^.+\\/,"")}:null;if(!n)return void this.clear();if(this.$hidden.val(""),this.$hidden.attr("name",""),this.$input.attr("name",this.name),"image"===this.type&&this.$preview.length>0&&("undefined"!=typeof n.type?n.type.match("image.*"):n.name.match(/\.(gif|png|jpe?g)$/i))&&"undefined"!=typeof FileReader){var i=new FileReader,a=this.$preview,r=this.$element;i.onload=function(e){a.html('<img alt="upload" src="'+e.target.result+'" '+("none"!=a.css("max-height")?'style="max-height: '+a.css("max-height")+';"':"")+" />"),r.addClass("fileupload-exists").removeClass("fileupload-new")},i.readAsDataURL(n)}else this.$preview.text(n.name),this.$element.addClass("fileupload-exists").removeClass("fileupload-new")}},clear:function(e){if(this.$hidden.val(""),this.$hidden.attr("name",this.name),this.$input.attr("name",""),navigator.userAgent.match(/msie/i)){var t=this.$input.clone(!0);this.$input.after(t),this.$input.remove(),this.$input=t}else this.$input.val("");this.$preview.html(""),this.$element.addClass("fileupload-new").removeClass("fileupload-exists"),e&&(this.$input.trigger("change",["clear"]),e.preventDefault())},reset:function(){this.clear(),this.$hidden.val(this.original.hiddenVal),this.$preview.html(this.original.preview),this.original.exists?this.$element.addClass("fileupload-exists").removeClass("fileupload-new"):this.$element.addClass("fileupload-new").removeClass("fileupload-exists")},trigger:function(e){this.$input.trigger("click"),e.preventDefault()}},e.fn.fileupload=function(n){return this.each(function(){var i=e(this),a=i.data("fileupload");a||i.data("fileupload",a=new t(this,n)),"string"==typeof n&&a[n]()})},e.fn.fileupload.Constructor=t,e(document).on("click.fileupload.data-api",'[data-provides="fileupload"]',function(t){var n=e(this);if(!n.data("fileupload")){n.fileupload(n.data());var i=e(t.target).closest('[data-dismiss="fileupload"],[data-trigger="fileupload"]');i.length>0&&(i.trigger("click.fileupload"),t.preventDefault())}})}(window.jQuery);