/*!

 handlebars v3.0.3

Copyright (C) 2011-2014 by Yehuda Katz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

@license
*/
!function(t,e){"object"==typeof exports&&"object"==typeof module?module.exports=e():"function"==typeof define&&define.amd?define(e):"object"==typeof exports?exports.Handlebars=e():t.Handlebars=e()}(this,function(){return function(t){function e(r){if(n[r])return n[r].exports;var i=n[r]={exports:{},id:r,loaded:!1};return t[r].call(i.exports,i,i.exports,e),i.loaded=!0,i.exports}var n={};return e.m=t,e.c=n,e.p="",e(0)}([function(t,e,n){"use strict";function r(){var t=new a.HandlebarsEnvironment;return h.extend(t,a),t.SafeString=u["default"],t.Exception=l["default"],t.Utils=h,t.escapeExpression=h.escapeExpression,t.VM=f,t.template=function(e){return f.template(e,t)},t}var i=n(7)["default"];e.__esModule=!0;var o=n(1),a=i(o),s=n(2),u=i(s),c=n(3),l=i(c),p=n(4),h=i(p),d=n(5),f=i(d),m=n(6),g=i(m),v=r();v.create=r,g["default"](v),v["default"]=v,e["default"]=v,t.exports=e["default"]},function(t,e,n){"use strict";function r(t,e){this.helpers=t||{},this.partials=e||{},i(this)}function i(t){t.registerHelper("helperMissing",function(){if(1===arguments.length)return void 0;throw new l["default"]('Missing helper: "'+arguments[arguments.length-1].name+'"')}),t.registerHelper("blockHelperMissing",function(e,n){var r=n.inverse,i=n.fn;if(e===!0)return i(this);if(e===!1||null==e)return r(this);if(f(e))return e.length>0?(n.ids&&(n.ids=[n.name]),t.helpers.each(e,n)):r(this);if(n.data&&n.ids){var a=o(n.data);a.contextPath=u.appendContextPath(n.data.contextPath,n.name),n={data:a}}return i(e,n)}),t.registerHelper("each",function(t,e){function n(e,n,i){c&&(c.key=e,c.index=n,c.first=0===n,c.last=!!i,p&&(c.contextPath=p+e)),s+=r(t[e],{data:c,blockParams:u.blockParams([t[e],e],[p+e,null])})}if(!e)throw new l["default"]("Must pass iterator to #each");var r=e.fn,i=e.inverse,a=0,s="",c=void 0,p=void 0;if(e.data&&e.ids&&(p=u.appendContextPath(e.data.contextPath,e.ids[0])+"."),m(t)&&(t=t.call(this)),e.data&&(c=o(e.data)),t&&"object"==typeof t)if(f(t))for(var h=t.length;h>a;a++)n(a,a,a===t.length-1);else{var d=void 0;for(var g in t)t.hasOwnProperty(g)&&(d&&n(d,a-1),d=g,a++);d&&n(d,a-1,!0)}return 0===a&&(s=i(this)),s}),t.registerHelper("if",function(t,e){return m(t)&&(t=t.call(this)),!e.hash.includeZero&&!t||u.isEmpty(t)?e.inverse(this):e.fn(this)}),t.registerHelper("unless",function(e,n){return t.helpers["if"].call(this,e,{fn:n.inverse,inverse:n.fn,hash:n.hash})}),t.registerHelper("with",function(t,e){m(t)&&(t=t.call(this));var n=e.fn;if(u.isEmpty(t))return e.inverse(this);if(e.data&&e.ids){var r=o(e.data);r.contextPath=u.appendContextPath(e.data.contextPath,e.ids[0]),e={data:r}}return n(t,e)}),t.registerHelper("log",function(e,n){var r=n.data&&null!=n.data.level?parseInt(n.data.level,10):1;t.log(r,e)}),t.registerHelper("lookup",function(t,e){return t&&t[e]})}function o(t){var e=u.extend({},t);return e._parent=t,e}var a=n(7)["default"];e.__esModule=!0,e.HandlebarsEnvironment=r,e.createFrame=o;var s=n(4),u=a(s),c=n(3),l=a(c),p="3.0.1";e.VERSION=p;var h=6;e.COMPILER_REVISION=h;var d={1:"<= 1.0.rc.2",2:"== 1.0.0-rc.3",3:"== 1.0.0-rc.4",4:"== 1.x.x",5:"== 2.0.0-alpha.x",6:">= 2.0.0-beta.1"};e.REVISION_CHANGES=d;var f=u.isArray,m=u.isFunction,g=u.toString,v="[object Object]";r.prototype={constructor:r,logger:y,log:b,registerHelper:function(t,e){if(g.call(t)===v){if(e)throw new l["default"]("Arg not supported with multiple helpers");u.extend(this.helpers,t)}else this.helpers[t]=e},unregisterHelper:function(t){delete this.helpers[t]},registerPartial:function(t,e){if(g.call(t)===v)u.extend(this.partials,t);else{if("undefined"==typeof e)throw new l["default"]("Attempting to register a partial as undefined");this.partials[t]=e}},unregisterPartial:function(t){delete this.partials[t]}};var y={methodMap:{0:"debug",1:"info",2:"warn",3:"error"},DEBUG:0,INFO:1,WARN:2,ERROR:3,level:1,log:function(t,e){if("undefined"!=typeof console&&y.level<=t){var n=y.methodMap[t];(console[n]||console.log).call(console,e)}}};e.logger=y;var b=y.log;e.log=b},function(t,e){"use strict";function n(t){this.string=t}e.__esModule=!0,n.prototype.toString=n.prototype.toHTML=function(){return""+this.string},e["default"]=n,t.exports=e["default"]},function(t,e){"use strict";function n(t,e){var i=e&&e.loc,o=void 0,a=void 0;i&&(o=i.start.line,a=i.start.column,t+=" - "+o+":"+a);for(var s=Error.prototype.constructor.call(this,t),u=0;u<r.length;u++)this[r[u]]=s[r[u]];Error.captureStackTrace&&Error.captureStackTrace(this,n),i&&(this.lineNumber=o,this.column=a)}e.__esModule=!0;var r=["description","fileName","lineNumber","message","name","number","stack"];n.prototype=new Error,e["default"]=n,t.exports=e["default"]},function(t,e){"use strict";function n(t){return c[t]}function r(t){for(var e=1;e<arguments.length;e++)for(var n in arguments[e])Object.prototype.hasOwnProperty.call(arguments[e],n)&&(t[n]=arguments[e][n]);return t}function i(t,e){for(var n=0,r=t.length;r>n;n++)if(t[n]===e)return n;return-1}function o(t){if("string"!=typeof t){if(t&&t.toHTML)return t.toHTML();if(null==t)return"";if(!t)return t+"";t=""+t}return p.test(t)?t.replace(l,n):t}function a(t){return t||0===t?f(t)&&0===t.length?!0:!1:!0}function s(t,e){return t.path=e,t}function u(t,e){return(t?t+".":"")+e}e.__esModule=!0,e.extend=r,e.indexOf=i,e.escapeExpression=o,e.isEmpty=a,e.blockParams=s,e.appendContextPath=u;var c={"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#x27;","`":"&#x60;"},l=/[&<>"'`]/g,p=/[&<>"'`]/,h=Object.prototype.toString;e.toString=h;var d=function(t){return"function"==typeof t};d(/x/)&&(e.isFunction=d=function(t){return"function"==typeof t&&"[object Function]"===h.call(t)});var d;e.isFunction=d;var f=Array.isArray||function(t){return t&&"object"==typeof t?"[object Array]"===h.call(t):!1};e.isArray=f},function(t,e,n){"use strict";function r(t){var e=t&&t[0]||1,n=m.COMPILER_REVISION;if(e!==n){if(n>e){var r=m.REVISION_CHANGES[n],i=m.REVISION_CHANGES[e];throw new f["default"]("Template was precompiled with an older version of Handlebars than the current runtime. Please update your precompiler to a newer version ("+r+") or downgrade your runtime to an older version ("+i+").")}throw new f["default"]("Template was precompiled with a newer version of Handlebars than the current runtime. Please update your runtime to a newer version ("+t[1]+").")}}function i(t,e){function n(n,r,i){i.hash&&(r=h.extend({},r,i.hash)),n=e.VM.resolvePartial.call(this,n,r,i);var o=e.VM.invokePartial.call(this,n,r,i);if(null==o&&e.compile&&(i.partials[i.name]=e.compile(n,t.compilerOptions,e),o=i.partials[i.name](r,i)),null!=o){if(i.indent){for(var a=o.split("\n"),s=0,u=a.length;u>s&&(a[s]||s+1!==u);s++)a[s]=i.indent+a[s];o=a.join("\n")}return o}throw new f["default"]("The partial "+i.name+" could not be compiled when running in runtime-only mode")}function r(e){var n=void 0===arguments[1]?{}:arguments[1],o=n.data;r._setup(n),!n.partial&&t.useData&&(o=c(e,o));var a=void 0,s=t.useBlockParams?[]:void 0;return t.useDepths&&(a=n.depths?[e].concat(n.depths):[e]),t.main.call(i,e,i.helpers,i.partials,o,s,a)}if(!e)throw new f["default"]("No environment passed to template");if(!t||!t.main)throw new f["default"]("Unknown template object: "+typeof t);e.VM.checkRevision(t.compiler);var i={strict:function(t,e){if(!(e in t))throw new f["default"]('"'+e+'" not defined in '+t);return t[e]},lookup:function(t,e){for(var n=t.length,r=0;n>r;r++)if(t[r]&&null!=t[r][e])return t[r][e]},lambda:function(t,e){return"function"==typeof t?t.call(e):t},escapeExpression:h.escapeExpression,invokePartial:n,fn:function(e){return t[e]},programs:[],program:function(t,e,n,r,i){var a=this.programs[t],s=this.fn(t);return e||i||r||n?a=o(this,t,s,e,n,r,i):a||(a=this.programs[t]=o(this,t,s)),a},data:function(t,e){for(;t&&e--;)t=t._parent;return t},merge:function(t,e){var n=t||e;return t&&e&&t!==e&&(n=h.extend({},e,t)),n},noop:e.VM.noop,compilerInfo:t.compiler};return r.isTop=!0,r._setup=function(n){n.partial?(i.helpers=n.helpers,i.partials=n.partials):(i.helpers=i.merge(n.helpers,e.helpers),t.usePartial&&(i.partials=i.merge(n.partials,e.partials)))},r._child=function(e,n,r,a){if(t.useBlockParams&&!r)throw new f["default"]("must pass block params");if(t.useDepths&&!a)throw new f["default"]("must pass parent depths");return o(i,e,t[e],n,0,r,a)},r}function o(t,e,n,r,i,o,a){function s(e){var i=void 0===arguments[1]?{}:arguments[1];return n.call(t,e,t.helpers,t.partials,i.data||r,o&&[i.blockParams].concat(o),a&&[e].concat(a))}return s.program=e,s.depth=a?a.length:0,s.blockParams=i||0,s}function a(t,e,n){return t?t.call||n.name||(n.name=t,t=n.partials[t]):t=n.partials[n.name],t}function s(t,e,n){if(n.partial=!0,void 0===t)throw new f["default"]("The partial "+n.name+" could not be found");return t instanceof Function?t(e,n):void 0}function u(){return""}function c(t,e){return e&&"root"in e||(e=e?m.createFrame(e):{},e.root=t),e}var l=n(7)["default"];e.__esModule=!0,e.checkRevision=r,e.template=i,e.wrapProgram=o,e.resolvePartial=a,e.invokePartial=s,e.noop=u;var p=n(4),h=l(p),d=n(3),f=l(d),m=n(1)},function(t,e){(function(n){"use strict";e.__esModule=!0,e["default"]=function(t){var e="undefined"!=typeof n?n:window,r=e.Handlebars;t.noConflict=function(){e.Handlebars===t&&(e.Handlebars=r)}},t.exports=e["default"]}).call(e,function(){return this}())},function(t,e){"use strict";e["default"]=function(t){return t&&t.__esModule?t:{"default":t}},e.__esModule=!0}])});