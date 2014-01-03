!function(e,t){"use strict";"function"==typeof define&&define.amd?define(["underscore","backbone"],t):e.Backbone.Poller=t(e._,e.Backbone)}(this,function(e,t){"use strict";function i(t){return e.find(c,function(e){return e.model===t})}function n(e,t){this.model=e,this.set(t)}function a(t){if(r(t)){var i=e.extend({},t.options,{success:function(e,i){t.trigger("success",e,i),s(t)},error:function(e,i){t.stop({silent:!0}),t.trigger("error",e,i)}});t.trigger("fetch",t.model),t.xhr=t.model.fetch(i)}}function s(t){r(t)&&(t.timeoutId=e.delay(a,t.options.delay,t))}function r(e){return e.options.active?e.options.condition(e.model)!==!0?(e.stop({silent:!0}),e.trigger("complete",e.model),!1):!0:!1}var o={delay:1e3,condition:function(){return!0}},l=["start","stop","fetch","success","error","complete"],c=[],h={get:function(e,t){var a=i(e);return a?a.set(t):(a=new n(e,t),c.push(a)),t&&t.autostart===!0&&a.start({silent:!0}),a},size:function(){return c.length},reset:function(){for(;c.length;)c.pop().stop()}};return e.extend(n.prototype,t.Events,{set:function(i){return this.options=e.extend({},o,i||{}),this.options.flush&&this.off(),e.each(l,function(t){var i=this.options[t];e.isFunction(i)&&(this.off(t,i,this),this.on(t,i,this))},this),this.model instanceof t.Model&&this.model.on("destroy",this.stop,this),this.stop({silent:!0})},start:function(e){return this.active()||(e&&e.silent||this.trigger("start",this.model),this.options.active=!0,this.options.delayed?s(this):a(this)),this},stop:function(e){return e&&e.silent||this.trigger("stop",this.model),this.options.active=!1,this.xhr&&this.xhr.abort&&this.xhr.abort(),this.xhr=null,clearTimeout(this.timeoutId),this.timeoutId=null,this},active:function(){return this.options.active===!0}}),h.prototype=n.prototype,h});