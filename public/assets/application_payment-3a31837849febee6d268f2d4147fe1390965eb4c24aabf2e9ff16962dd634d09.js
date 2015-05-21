function render_loading_invoice(e,t){var n=_.template(jQuery("#loading_invoice_template").html());jQuery(e).html(n(t))}function render_empty_invoice(e,t){var n=_.template(jQuery("#empty_invoice_template").html());jQuery(e).html(n(t))}function render_invoice_table(e,t){var n=_.template(jQuery("#invoice_table_template").html());jQuery(e).html(n(t))}function render_invoice_row(e,t){var n=_.template(jQuery("#invoice_row_template").html());jQuery(e).append(n({invoice:t}))}function render_payment_history(e,t){if(0==t.length)console.debug("Rendering empty invoices"),render_empty_invoice(e,{});else{var n="#invoice_table > tbody";console.debug("Rendering table"),render_invoice_table(e,{}),_.each(t,function(e){render_invoice_row(n,e)})}}function render_fail_invoice(e){var t=_.template(jQuery("#fail_invoice_template").html());jQuery(e).html(t({message:"Can not read payment history from Payment service"}))}(function(){var e=this,t=e._,n={},r=Array.prototype,i=Object.prototype,o=Function.prototype,a=r.push,s=r.slice,u=r.concat,l=i.toString,c=i.hasOwnProperty,p=r.forEach,f=r.map,d=r.reduce,h=r.reduceRight,m=r.filter,g=r.every,y=r.some,v=r.indexOf,b=r.lastIndexOf,w=Array.isArray,x=Object.keys,C=o.bind,S=function(e){return e instanceof S?e:this instanceof S?void(this._wrapped=e):new S(e)};"undefined"!=typeof exports?("undefined"!=typeof module&&module.exports&&(exports=module.exports=S),exports._=S):e._=S,S.VERSION="1.4.4";var E=S.each=S.forEach=function(e,t,r){if(null!=e)if(p&&e.forEach===p)e.forEach(t,r);else if(e.length===+e.length){for(var i=0,o=e.length;o>i;i++)if(t.call(r,e[i],i,e)===n)return}else for(var a in e)if(S.has(e,a)&&t.call(r,e[a],a,e)===n)return};S.map=S.collect=function(e,t,n){var r=[];return null==e?r:f&&e.map===f?e.map(t,n):(E(e,function(e,i,o){r[r.length]=t.call(n,e,i,o)}),r)};var T="Reduce of empty array with no initial value";S.reduce=S.foldl=S.inject=function(e,t,n,r){var i=arguments.length>2;if(null==e&&(e=[]),d&&e.reduce===d)return r&&(t=S.bind(t,r)),i?e.reduce(t,n):e.reduce(t);if(E(e,function(e,o,a){i?n=t.call(r,n,e,o,a):(n=e,i=!0)}),!i)throw new TypeError(T);return n},S.reduceRight=S.foldr=function(e,t,n,r){var i=arguments.length>2;if(null==e&&(e=[]),h&&e.reduceRight===h)return r&&(t=S.bind(t,r)),i?e.reduceRight(t,n):e.reduceRight(t);var o=e.length;if(o!==+o){var a=S.keys(e);o=a.length}if(E(e,function(s,u,l){u=a?a[--o]:--o,i?n=t.call(r,n,e[u],u,l):(n=e[u],i=!0)}),!i)throw new TypeError(T);return n},S.find=S.detect=function(e,t,n){var r;return k(e,function(e,i,o){return t.call(n,e,i,o)?(r=e,!0):void 0}),r},S.filter=S.select=function(e,t,n){var r=[];return null==e?r:m&&e.filter===m?e.filter(t,n):(E(e,function(e,i,o){t.call(n,e,i,o)&&(r[r.length]=e)}),r)},S.reject=function(e,t,n){return S.filter(e,function(e,r,i){return!t.call(n,e,r,i)},n)},S.every=S.all=function(e,t,r){t||(t=S.identity);var i=!0;return null==e?i:g&&e.every===g?e.every(t,r):(E(e,function(e,o,a){return(i=i&&t.call(r,e,o,a))?void 0:n}),!!i)};var k=S.some=S.any=function(e,t,r){t||(t=S.identity);var i=!1;return null==e?i:y&&e.some===y?e.some(t,r):(E(e,function(e,o,a){return i||(i=t.call(r,e,o,a))?n:void 0}),!!i)};S.contains=S.include=function(e,t){return null==e?!1:v&&e.indexOf===v?-1!=e.indexOf(t):k(e,function(e){return e===t})},S.invoke=function(e,t){var n=s.call(arguments,2),r=S.isFunction(t);return S.map(e,function(e){return(r?t:e[t]).apply(e,n)})},S.pluck=function(e,t){return S.map(e,function(e){return e[t]})},S.where=function(e,t,n){return S.isEmpty(t)?n?null:[]:S[n?"find":"filter"](e,function(e){for(var n in t)if(t[n]!==e[n])return!1;return!0})},S.findWhere=function(e,t){return S.where(e,t,!0)},S.max=function(e,t,n){if(!t&&S.isArray(e)&&e[0]===+e[0]&&65535>e.length)return Math.max.apply(Math,e);if(!t&&S.isEmpty(e))return-1/0;var r={computed:-1/0,value:-1/0};return E(e,function(e,i,o){var a=t?t.call(n,e,i,o):e;a>=r.computed&&(r={value:e,computed:a})}),r.value},S.min=function(e,t,n){if(!t&&S.isArray(e)&&e[0]===+e[0]&&65535>e.length)return Math.min.apply(Math,e);if(!t&&S.isEmpty(e))return 1/0;var r={computed:1/0,value:1/0};return E(e,function(e,i,o){var a=t?t.call(n,e,i,o):e;r.computed>a&&(r={value:e,computed:a})}),r.value},S.shuffle=function(e){var t,n=0,r=[];return E(e,function(e){t=S.random(n++),r[n-1]=r[t],r[t]=e}),r};var A=function(e){return S.isFunction(e)?e:function(t){return t[e]}};S.sortBy=function(e,t,n){var r=A(t);return S.pluck(S.map(e,function(e,t,i){return{value:e,index:t,criteria:r.call(n,e,t,i)}}).sort(function(e,t){var n=e.criteria,r=t.criteria;if(n!==r){if(n>r||void 0===n)return 1;if(r>n||void 0===r)return-1}return e.index<t.index?-1:1}),"value")};var _=function(e,t,n,r){var i={},o=A(t||S.identity);return E(e,function(t,a){var s=o.call(n,t,a,e);r(i,s,t)}),i};S.groupBy=function(e,t,n){return _(e,t,n,function(e,t,n){(S.has(e,t)?e[t]:e[t]=[]).push(n)})},S.countBy=function(e,t,n){return _(e,t,n,function(e,t){S.has(e,t)||(e[t]=0),e[t]++})},S.sortedIndex=function(e,t,n,r){n=null==n?S.identity:A(n);for(var i=n.call(r,t),o=0,a=e.length;a>o;){var s=o+a>>>1;i>n.call(r,e[s])?o=s+1:a=s}return o},S.toArray=function(e){return e?S.isArray(e)?s.call(e):e.length===+e.length?S.map(e,S.identity):S.values(e):[]},S.size=function(e){return null==e?0:e.length===+e.length?e.length:S.keys(e).length},S.first=S.head=S.take=function(e,t,n){return null==e?void 0:null==t||n?e[0]:s.call(e,0,t)},S.initial=function(e,t,n){return s.call(e,0,e.length-(null==t||n?1:t))},S.last=function(e,t,n){return null==e?void 0:null==t||n?e[e.length-1]:s.call(e,Math.max(e.length-t,0))},S.rest=S.tail=S.drop=function(e,t,n){return s.call(e,null==t||n?1:t)},S.compact=function(e){return S.filter(e,S.identity)};var j=function(e,t,n){return E(e,function(e){S.isArray(e)?t?a.apply(n,e):j(e,t,n):n.push(e)}),n};S.flatten=function(e,t){return j(e,t,[])},S.without=function(e){return S.difference(e,s.call(arguments,1))},S.uniq=S.unique=function(e,t,n,r){S.isFunction(t)&&(r=n,n=t,t=!1);var i=n?S.map(e,n,r):e,o=[],a=[];return E(i,function(n,r){(t?r&&a[a.length-1]===n:S.contains(a,n))||(a.push(n),o.push(e[r]))}),o},S.union=function(){return S.uniq(u.apply(r,arguments))},S.intersection=function(e){var t=s.call(arguments,1);return S.filter(S.uniq(e),function(e){return S.every(t,function(t){return S.indexOf(t,e)>=0})})},S.difference=function(e){var t=u.apply(r,s.call(arguments,1));return S.filter(e,function(e){return!S.contains(t,e)})},S.zip=function(){for(var e=s.call(arguments),t=S.max(S.pluck(e,"length")),n=Array(t),r=0;t>r;r++)n[r]=S.pluck(e,""+r);return n},S.object=function(e,t){if(null==e)return{};for(var n={},r=0,i=e.length;i>r;r++)t?n[e[r]]=t[r]:n[e[r][0]]=e[r][1];return n},S.indexOf=function(e,t,n){if(null==e)return-1;var r=0,i=e.length;if(n){if("number"!=typeof n)return r=S.sortedIndex(e,t),e[r]===t?r:-1;r=0>n?Math.max(0,i+n):n}if(v&&e.indexOf===v)return e.indexOf(t,n);for(;i>r;r++)if(e[r]===t)return r;return-1},S.lastIndexOf=function(e,t,n){if(null==e)return-1;var r=null!=n;if(b&&e.lastIndexOf===b)return r?e.lastIndexOf(t,n):e.lastIndexOf(t);for(var i=r?n:e.length;i--;)if(e[i]===t)return i;return-1},S.range=function(e,t,n){1>=arguments.length&&(t=e||0,e=0),n=arguments[2]||1;for(var r=Math.max(Math.ceil((t-e)/n),0),i=0,o=Array(r);r>i;)o[i++]=e,e+=n;return o},S.bind=function(e,t){if(e.bind===C&&C)return C.apply(e,s.call(arguments,1));var n=s.call(arguments,2);return function(){return e.apply(t,n.concat(s.call(arguments)))}},S.partial=function(e){var t=s.call(arguments,1);return function(){return e.apply(this,t.concat(s.call(arguments)))}},S.bindAll=function(e){var t=s.call(arguments,1);return 0===t.length&&(t=S.functions(e)),E(t,function(t){e[t]=S.bind(e[t],e)}),e},S.memoize=function(e,t){var n={};return t||(t=S.identity),function(){var r=t.apply(this,arguments);return S.has(n,r)?n[r]:n[r]=e.apply(this,arguments)}},S.delay=function(e,t){var n=s.call(arguments,2);return setTimeout(function(){return e.apply(null,n)},t)},S.defer=function(e){return S.delay.apply(S,[e,1].concat(s.call(arguments,1)))},S.throttle=function(e,t){var n,r,i,o,a=0,s=function(){a=new Date,i=null,o=e.apply(n,r)};return function(){var u=new Date,l=t-(u-a);return n=this,r=arguments,0>=l?(clearTimeout(i),i=null,a=u,o=e.apply(n,r)):i||(i=setTimeout(s,l)),o}},S.debounce=function(e,t,n){var r,i;return function(){var o=this,a=arguments,s=function(){r=null,n||(i=e.apply(o,a))},u=n&&!r;return clearTimeout(r),r=setTimeout(s,t),u&&(i=e.apply(o,a)),i}},S.once=function(e){var t,n=!1;return function(){return n?t:(n=!0,t=e.apply(this,arguments),e=null,t)}},S.wrap=function(e,t){return function(){var n=[e];return a.apply(n,arguments),t.apply(this,n)}},S.compose=function(){var e=arguments;return function(){for(var t=arguments,n=e.length-1;n>=0;n--)t=[e[n].apply(this,t)];return t[0]}},S.after=function(e,t){return 0>=e?t():function(){return 1>--e?t.apply(this,arguments):void 0}},S.keys=x||function(e){if(e!==Object(e))throw new TypeError("Invalid object");var t=[];for(var n in e)S.has(e,n)&&(t[t.length]=n);return t},S.values=function(e){var t=[];for(var n in e)S.has(e,n)&&t.push(e[n]);return t},S.pairs=function(e){var t=[];for(var n in e)S.has(e,n)&&t.push([n,e[n]]);return t},S.invert=function(e){var t={};for(var n in e)S.has(e,n)&&(t[e[n]]=n);return t},S.functions=S.methods=function(e){var t=[];for(var n in e)S.isFunction(e[n])&&t.push(n);return t.sort()},S.extend=function(e){return E(s.call(arguments,1),function(t){if(t)for(var n in t)e[n]=t[n]}),e},S.pick=function(e){var t={},n=u.apply(r,s.call(arguments,1));return E(n,function(n){n in e&&(t[n]=e[n])}),t},S.omit=function(e){var t={},n=u.apply(r,s.call(arguments,1));for(var i in e)S.contains(n,i)||(t[i]=e[i]);return t},S.defaults=function(e){return E(s.call(arguments,1),function(t){if(t)for(var n in t)null==e[n]&&(e[n]=t[n])}),e},S.clone=function(e){return S.isObject(e)?S.isArray(e)?e.slice():S.extend({},e):e},S.tap=function(e,t){return t(e),e};var L=function(e,t,n,r){if(e===t)return 0!==e||1/e==1/t;if(null==e||null==t)return e===t;e instanceof S&&(e=e._wrapped),t instanceof S&&(t=t._wrapped);var i=l.call(e);if(i!=l.call(t))return!1;switch(i){case"[object String]":return e==t+"";case"[object Number]":return e!=+e?t!=+t:0==e?1/e==1/t:e==+t;case"[object Date]":case"[object Boolean]":return+e==+t;case"[object RegExp]":return e.source==t.source&&e.global==t.global&&e.multiline==t.multiline&&e.ignoreCase==t.ignoreCase}if("object"!=typeof e||"object"!=typeof t)return!1;for(var o=n.length;o--;)if(n[o]==e)return r[o]==t;n.push(e),r.push(t);var a=0,s=!0;if("[object Array]"==i){if(a=e.length,s=a==t.length)for(;a--&&(s=L(e[a],t[a],n,r)););}else{var u=e.constructor,c=t.constructor;if(u!==c&&!(S.isFunction(u)&&u instanceof u&&S.isFunction(c)&&c instanceof c))return!1;for(var p in e)if(S.has(e,p)&&(a++,!(s=S.has(t,p)&&L(e[p],t[p],n,r))))break;if(s){for(p in t)if(S.has(t,p)&&!a--)break;s=!a}}return n.pop(),r.pop(),s};S.isEqual=function(e,t){return L(e,t,[],[])},S.isEmpty=function(e){if(null==e)return!0;if(S.isArray(e)||S.isString(e))return 0===e.length;for(var t in e)if(S.has(e,t))return!1;return!0},S.isElement=function(e){return!(!e||1!==e.nodeType)},S.isArray=w||function(e){return"[object Array]"==l.call(e)},S.isObject=function(e){return e===Object(e)},E(["Arguments","Function","String","Number","Date","RegExp"],function(e){S["is"+e]=function(t){return l.call(t)=="[object "+e+"]"}}),S.isArguments(arguments)||(S.isArguments=function(e){return!(!e||!S.has(e,"callee"))}),"function"!=typeof/./&&(S.isFunction=function(e){return"function"==typeof e}),S.isFinite=function(e){return isFinite(e)&&!isNaN(parseFloat(e))},S.isNaN=function(e){return S.isNumber(e)&&e!=+e},S.isBoolean=function(e){return e===!0||e===!1||"[object Boolean]"==l.call(e)},S.isNull=function(e){return null===e},S.isUndefined=function(e){return void 0===e},S.has=function(e,t){return c.call(e,t)},S.noConflict=function(){return e._=t,this},S.identity=function(e){return e},S.times=function(e,t,n){for(var r=Array(e),i=0;e>i;i++)r[i]=t.call(n,i);return r},S.random=function(e,t){return null==t&&(t=e,e=0),e+Math.floor(Math.random()*(t-e+1))};var N={escape:{"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#x27;","/":"&#x2F;"}};N.unescape=S.invert(N.escape);var $={escape:RegExp("["+S.keys(N.escape).join("")+"]","g"),unescape:RegExp("("+S.keys(N.unescape).join("|")+")","g")};S.each(["escape","unescape"],function(e){S[e]=function(t){return null==t?"":(""+t).replace($[e],function(t){return N[e][t]})}}),S.result=function(e,t){if(null==e)return null;var n=e[t];return S.isFunction(n)?n.call(e):n},S.mixin=function(e){E(S.functions(e),function(t){var n=S[t]=e[t];S.prototype[t]=function(){var e=[this._wrapped];return a.apply(e,arguments),M.call(this,n.apply(S,e))}})};var D=0;S.uniqueId=function(e){var t=++D+"";return e?e+t:t},S.templateSettings={evaluate:/<%([\s\S]+?)%>/g,interpolate:/<%=([\s\S]+?)%>/g,escape:/<%-([\s\S]+?)%>/g};var I=/(.)^/,O={"'":"'","\\":"\\","\r":"r","\n":"n","	":"t","\u2028":"u2028","\u2029":"u2029"},P=/\\|'|\r|\n|\t|\u2028|\u2029/g;S.template=function(e,t,n){var r;n=S.defaults({},n,S.templateSettings);var i=RegExp([(n.escape||I).source,(n.interpolate||I).source,(n.evaluate||I).source].join("|")+"|$","g"),o=0,a="__p+='";e.replace(i,function(t,n,r,i,s){return a+=e.slice(o,s).replace(P,function(e){return"\\"+O[e]}),n&&(a+="'+\n((__t=("+n+"))==null?'':_.escape(__t))+\n'"),r&&(a+="'+\n((__t=("+r+"))==null?'':__t)+\n'"),i&&(a+="';\n"+i+"\n__p+='"),o=s+t.length,t}),a+="';\n",n.variable||(a="with(obj||{}){\n"+a+"}\n"),a="var __t,__p='',__j=Array.prototype.join,print=function(){__p+=__j.call(arguments,'');};\n"+a+"return __p;\n";try{r=Function(n.variable||"obj","_",a)}catch(s){throw s.source=a,s}if(t)return r(t,S);var u=function(e){return r.call(this,e,S)};return u.source="function("+(n.variable||"obj")+"){\n"+a+"}",u},S.chain=function(e){return S(e).chain()};var M=function(e){return this._chain?S(e).chain():e};S.mixin(S),E(["pop","push","reverse","shift","sort","splice","unshift"],function(e){var t=r[e];S.prototype[e]=function(){var n=this._wrapped;return t.apply(n,arguments),"shift"!=e&&"splice"!=e||0!==n.length||delete n[0],M.call(this,n)}}),E(["concat","join","slice"],function(e){var t=r[e];S.prototype[e]=function(){return M.call(this,t.apply(this._wrapped,arguments))}}),S.extend(S.prototype,{chain:function(){return this._chain=!0,this},value:function(){return this._wrapped}})}).call(this),jQuery(document).ready(function(){if(jQuery("#payment_history").length){console.debug("Going to render payment history..."),_.templateSettings={interpolate:/\{\{\=(.+?)\}\}/g,evaluate:/\{\{(.+?)\}\}/g};var e="#payment_history";render_loading_invoice(e);var t=jQuery.getJSON("/settings/payments.json");t.done(function(t,n){console.debug("Got invoices: "+n),render_payment_history(e,t)}),t.fail(function(t,n){console.debug("Failed invoices: "+n),render_fail_invoice(e,t)})}});