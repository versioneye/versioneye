/*!
 * jQuery.ScrollTo
 * Copyright (c) 2007-2012 Ariel Flesler - aflesler(at)gmail(dot)com | http://flesler.blogspot.com
 * Dual licensed under MIT and GPL.
 * Date: 4/09/2012
 *
 * @projectDescription Easy element scrolling using jQuery.
 * http://flesler.blogspot.com/2007/10/jqueryscrollto.html
 * @author Ariel Flesler
 * @version 1.4.3.1
 *
 * @id jQuery.scrollTo
 * @id jQuery.fn.scrollTo
 * @param {String, Number, DOMElement, jQuery, Object} target Where to scroll the matched elements.
 *    The different options for target are:
 *      - A number position (will be applied to all axes).
 *      - A string position ('44', '100px', '+=90', etc ) will be applied to all axes
 *      - A jQuery/DOM element ( logically, child of the element to scroll )
 *      - A string selector, that will be relative to the element to scroll ( 'li:eq(2)', etc )
 *      - A hash { top:x, left:y }, x and y can be any kind of number/string like above.
 *      - A percentage of the container's dimension/s, for example: 50% to go to the middle.
 *      - The string 'max' for go-to-end.
 * @param {Number, Function} duration The OVERALL length of the animation, this argument can be the settings object instead.
 * @param {Object,Function} settings Optional set of settings or the onAfter callback.
 *   @option {String} axis Which axis must be scrolled, use 'x', 'y', 'xy' or 'yx'.
 *   @option {Number, Function} duration The OVERALL length of the animation.
 *   @option {String} easing The easing method for the animation.
 *   @option {Boolean} margin If true, the margin of the target element will be deducted from the final position.
 *   @option {Object, Number} offset Add/deduct from the end position. One number for both axes or { top:x, left:y }.
 *   @option {Object, Number} over Add/deduct the height/width multiplied by 'over', can be { top:x, left:y } when using both axes.
 *   @option {Boolean} queue If true, and both axis are given, the 2nd axis will only be animated after the first one ends.
 *   @option {Function} onAfter Function to be called after the scrolling ends.
 *   @option {Function} onAfterFirst If queuing is activated, this function will be called after the first scrolling ends.
 * @return {jQuery} Returns the same jQuery object, for chaining.
 *
 * @desc Scroll to a fixed position
 * @example $('div').scrollTo( 340 );
 *
 * @desc Scroll relatively to the actual position
 * @example $('div').scrollTo( '+=340px', { axis:'y' } );
 *
 * @desc Scroll using a selector (relative to the scrolled element)
 * @example $('div').scrollTo( 'p.paragraph:eq(2)', 500, { easing:'swing', queue:true, axis:'xy' } );
 *
 * @desc Scroll to a DOM element (same for jQuery object)
 * @example var second_child = document.getElementById('container').firstChild.nextSibling;
 *          $('#container').scrollTo( second_child, { duration:500, axis:'x', onAfter:function(){
 *              alert('scrolled!!');
 *          }});
 *
 * @desc Scroll on both axes, to different values
 * @example $('div').scrollTo( { top: 300, left:'+=200' }, { axis:'xy', offset:-20 } );
 */
!function(e){function t(e){return"object"==typeof e?e:{top:e,left:e}}var n=e.scrollTo=function(t,n,r){e(window).scrollTo(t,n,r)};n.defaults={axis:"xy",duration:parseFloat(e.fn.jquery)>=1.3?0:1,limit:!0},n.window=function(t){return e(window)._scrollable()},e.fn._scrollable=function(){return this.map(function(){var t=this,n=!t.nodeName||-1!=e.inArray(t.nodeName.toLowerCase(),["iframe","#document","html","body"]);if(!n)return t;var r=(t.contentWindow||t).document||t.ownerDocument||t;return/webkit/i.test(navigator.userAgent)||"BackCompat"==r.compatMode?r.body:r.documentElement})},e.fn.scrollTo=function(r,i,o){return"object"==typeof i&&(o=i,i=0),"function"==typeof o&&(o={onAfter:o}),"max"==r&&(r=9e9),o=e.extend({},n.defaults,o),i=i||o.duration,o.queue=o.queue&&o.axis.length>1,o.queue&&(i/=2),o.offset=t(o.offset),o.over=t(o.over),this._scrollable().each(function(){function a(e){l.animate(p,i,o.easing,e&&function(){e.call(this,r,o)})}if(null!=r){var s,u=this,l=e(u),c=r,p={},d=l.is("html,body");switch(typeof c){case"number":case"string":if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(c)){c=t(c);break}if(c=e(c,this),!c.length)return;case"object":(c.is||c.style)&&(s=(c=e(c)).offset())}e.each(o.axis.split(""),function(e,t){var r="x"==t?"Left":"Top",i=r.toLowerCase(),f="scroll"+r,h=u[f],m=n.max(u,t);if(s)p[f]=s[i]+(d?0:h-l.offset()[i]),o.margin&&(p[f]-=parseInt(c.css("margin"+r))||0,p[f]-=parseInt(c.css("border"+r+"Width"))||0),p[f]+=o.offset[i]||0,o.over[i]&&(p[f]+=c["x"==t?"width":"height"]()*o.over[i]);else{var g=c[i];p[f]=g.slice&&"%"==g.slice(-1)?parseFloat(g)/100*m:g}o.limit&&/^\d+$/.test(p[f])&&(p[f]=p[f]<=0?0:Math.min(p[f],m)),!e&&o.queue&&(h!=p[f]&&a(o.onAfterFirst),delete p[f])}),a(o.onAfter)}}).end()},n.max=function(t,n){var r="x"==n?"Width":"Height",i="scroll"+r;if(!e(t).is("html,body"))return t[i]-e(t)[r.toLowerCase()]();var o="client"+r,a=t.ownerDocument.documentElement,s=t.ownerDocument.body;return Math.max(a[i],s[i])-Math.min(a[o],s[o])}}(jQuery);