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
!function(e){function t(e){return"object"==typeof e?e:{top:e,left:e}}var n=e.scrollTo=function(t,n,i){e(window).scrollTo(t,n,i)};n.defaults={axis:"xy",duration:parseFloat(e.fn.jquery)>=1.3?0:1,limit:!0},n.window=function(){return e(window)._scrollable()},e.fn._scrollable=function(){return this.map(function(){var t=this,n=!t.nodeName||-1!=e.inArray(t.nodeName.toLowerCase(),["iframe","#document","html","body"]);if(!n)return t;var i=(t.contentWindow||t).document||t.ownerDocument||t;return/webkit/i.test(navigator.userAgent)||"BackCompat"==i.compatMode?i.body:i.documentElement})},e.fn.scrollTo=function(i,r,a){return"object"==typeof r&&(a=r,r=0),"function"==typeof a&&(a={onAfter:a}),"max"==i&&(i=9e9),a=e.extend({},n.defaults,a),r=r||a.duration,a.queue=a.queue&&a.axis.length>1,a.queue&&(r/=2),a.offset=t(a.offset),a.over=t(a.over),this._scrollable().each(function(){function o(e){c.animate(d,r,a.easing,e&&function(){e.call(this,i,a)})}if(null!=i){var s,l=this,c=e(l),u=i,d={},f=c.is("html,body");switch(typeof u){case"number":case"string":if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(u)){u=t(u);break}if(u=e(u,this),!u.length)return;case"object":(u.is||u.style)&&(s=(u=e(u)).offset())}e.each(a.axis.split(""),function(e,t){var i="x"==t?"Left":"Top",r=i.toLowerCase(),p="scroll"+i,h=l[p],m=n.max(l,t);if(s)d[p]=s[r]+(f?0:h-c.offset()[r]),a.margin&&(d[p]-=parseInt(u.css("margin"+i))||0,d[p]-=parseInt(u.css("border"+i+"Width"))||0),d[p]+=a.offset[r]||0,a.over[r]&&(d[p]+=u["x"==t?"width":"height"]()*a.over[r]);else{var g=u[r];d[p]=g.slice&&"%"==g.slice(-1)?parseFloat(g)/100*m:g}a.limit&&/^\d+$/.test(d[p])&&(d[p]=d[p]<=0?0:Math.min(d[p],m)),!e&&a.queue&&(h!=d[p]&&o(a.onAfterFirst),delete d[p])}),o(a.onAfter)}}).end()},n.max=function(t,n){var i="x"==n?"Width":"Height",r="scroll"+i;if(!e(t).is("html,body"))return t[r]-e(t)[i.toLowerCase()]();var a="client"+i,o=t.ownerDocument.documentElement,s=t.ownerDocument.body;return Math.max(o[r],s[r])-Math.min(o[a],s[a])}}(jQuery);