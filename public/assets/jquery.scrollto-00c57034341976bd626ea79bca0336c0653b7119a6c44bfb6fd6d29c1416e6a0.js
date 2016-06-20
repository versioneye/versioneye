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
!function(t){function e(t){return"object"==typeof t?t:{top:t,left:t}}var n=t.scrollTo=function(e,n,i){t(window).scrollTo(e,n,i)};n.defaults={axis:"xy",duration:parseFloat(t.fn.jquery)>=1.3?0:1,limit:!0},n.window=function(){return t(window)._scrollable()},t.fn._scrollable=function(){return this.map(function(){var e=this,n=!e.nodeName||-1!=t.inArray(e.nodeName.toLowerCase(),["iframe","#document","html","body"]);if(!n)return e;var i=(e.contentWindow||e).document||e.ownerDocument||e;return/webkit/i.test(navigator.userAgent)||"BackCompat"==i.compatMode?i.body:i.documentElement})},t.fn.scrollTo=function(i,r,o){return"object"==typeof r&&(o=r,r=0),"function"==typeof o&&(o={onAfter:o}),"max"==i&&(i=9e9),o=t.extend({},n.defaults,o),r=r||o.duration,o.queue=o.queue&&o.axis.length>1,o.queue&&(r/=2),o.offset=e(o.offset),o.over=e(o.over),this._scrollable().each(function(){function s(t){l.animate(h,r,o.easing,t&&function(){t.call(this,i,o)})}if(null!=i){var a,u=this,l=t(u),c=i,h={},d=l.is("html,body");switch(typeof c){case"number":case"string":if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(c)){c=e(c);break}if(c=t(c,this),!c.length)return;case"object":(c.is||c.style)&&(a=(c=t(c)).offset())}t.each(o.axis.split(""),function(t,e){var i="x"==e?"Left":"Top",r=i.toLowerCase(),p="scroll"+i,f=u[p],m=n.max(u,e);if(a)h[p]=a[r]+(d?0:f-l.offset()[r]),o.margin&&(h[p]-=parseInt(c.css("margin"+i))||0,h[p]-=parseInt(c.css("border"+i+"Width"))||0),h[p]+=o.offset[r]||0,o.over[r]&&(h[p]+=c["x"==e?"width":"height"]()*o.over[r]);else{var g=c[r];h[p]=g.slice&&"%"==g.slice(-1)?parseFloat(g)/100*m:g}o.limit&&/^\d+$/.test(h[p])&&(h[p]=h[p]<=0?0:Math.min(h[p],m)),!t&&o.queue&&(f!=h[p]&&s(o.onAfterFirst),delete h[p])}),s(o.onAfter)}}).end()},n.max=function(e,n){var i="x"==n?"Width":"Height",r="scroll"+i;if(!t(e).is("html,body"))return e[r]-t(e)[i.toLowerCase()]();var o="client"+i,s=e.ownerDocument.documentElement,a=e.ownerDocument.body;return Math.max(s[r],a[r])-Math.min(s[o],a[o])}}(jQuery);