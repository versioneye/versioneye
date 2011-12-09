/**
 * Unobtrusive scripting adapter for jQuery
 *
 * Requires jQuery 1.6.0 or later.
 * https://github.com/rails/jquery-ujs

 * Uploading file using rails.js
 * =============================
 *
 * By default, browsers do not allow files to be uploaded via AJAX. As a result, if there are any non-blank file fields
 * in the remote form, this adapter aborts the AJAX submission and allows the form to submit through standard means.
 *
 * The `ajax:aborted:file` event allows you to bind your own handler to process the form submission however you wish.
 *
 * Ex:
 *     $('form').live('ajax:aborted:file', function(event, elements){
 *       // Implement own remote file-transfer handler here for non-blank file inputs passed in `elements`.
 *       // Returning false in this handler tells rails.js to disallow standard form submission
 *       return false;
 *     });
 *
 * The `ajax:aborted:file` event is fired when a file-type input is detected with a non-blank value.
 *
 * Third-party tools can use this hook to detect when an AJAX file upload is attempted, and then use
 * techniques like the iframe method to upload the file instead.
 *
 * Required fields in rails.js
 * ===========================
 *
 * If any blank required inputs (required="required") are detected in the remote form, the whole form submission
 * is canceled. Note that this is unlike file inputs, which still allow standard (non-AJAX) form submission.
 *
 * The `ajax:aborted:required` event allows you to bind your own handler to inform the user of blank required inputs.
 *
 * !! Note that Opera does not fire the form's submit event if there are blank required inputs, so this event may never
 *    get fired in Opera. This event is what causes other browsers to exhibit the same submit-aborting behavior.
 *
 * Ex:
 *     $('form').live('ajax:aborted:required', function(event, elements){
 *       // Returning false in this handler tells rails.js to submit the form anyway.
 *       // The blank required inputs are passed to this function in `elements`.
 *       return ! confirm("Would you like to submit the form with missing info?");
 *     });
 */
(function(a,b){var c;a.rails=c={linkClickSelector:"a[data-confirm], a[data-method], a[data-remote], a[data-disable-with]",inputChangeSelector:"select[data-remote], input[data-remote], textarea[data-remote]",formSubmitSelector:"form",formInputClickSelector:"form input[type=submit], form input[type=image], form button[type=submit], form button:not(button[type])",disableSelector:"input[data-disable-with], button[data-disable-with], textarea[data-disable-with]",enableSelector:"input[data-disable-with]:disabled, button[data-disable-with]:disabled, textarea[data-disable-with]:disabled",requiredInputSelector:"input[name][required]:not([disabled]),textarea[name][required]:not([disabled])",fileInputSelector:"input:file",linkDisableSelector:"a[data-disable-with]",CSRFProtection:function(b){var c=a('meta[name="csrf-token"]').attr("content");c&&b.setRequestHeader("X-CSRF-Token",c)},fire:function(b,c,d){var e=a.Event(c);return b.trigger(e,d),e.result!==!1},confirm:function(a){return confirm(a)},ajax:function(b){return a.ajax(b)},handleRemote:function(d){var e,f,g,h=d.data("cross-domain")||null,i=d.data("type")||a.ajaxSettings&&a.ajaxSettings.dataType,j;if(c.fire(d,"ajax:before")){if(d.is("form")){e=d.attr("method"),f=d.attr("action"),g=d.serializeArray();var k=d.data("ujs:submit-button");k&&(g.push(k),d.data("ujs:submit-button",null))}else d.is(c.inputChangeSelector)?(e=d.data("method"),f=d.data("url"),g=d.serialize(),d.data("params")&&(g=g+"&"+d.data("params"))):(e=d.data("method"),f=d.attr("href"),g=d.data("params")||null);j={type:e||"GET",data:g,dataType:i,crossDomain:h,beforeSend:function(a,e){return e.dataType===b&&a.setRequestHeader("accept","*/*;q=0.5, "+e.accepts.script),c.fire(d,"ajax:beforeSend",[a,e])},success:function(a,b,c){d.trigger("ajax:success",[a,b,c])},complete:function(a,b){d.trigger("ajax:complete",[a,b])},error:function(a,b,c){d.trigger("ajax:error",[a,b,c])}},f&&(j.url=f),c.ajax(j)}},handleMethod:function(c){var d=c.attr("href"),e=c.data("method"),f=c.attr("target"),g=a("meta[name=csrf-token]").attr("content"),h=a("meta[name=csrf-param]").attr("content"),i=a('<form method="post" action="'+d+'"></form>'),j='<input name="_method" value="'+e+'" type="hidden" />';h!==b&&g!==b&&(j+='<input name="'+h+'" value="'+g+'" type="hidden" />'),f&&i.attr("target",f),i.hide().append(j).appendTo("body"),i.submit()},disableFormElements:function(b){b.find(c.disableSelector).each(function(){var b=a(this),c=b.is("button")?"html":"val";b.data("ujs:enable-with",b[c]()),b[c](b.data("disable-with")),b.prop("disabled",!0)})},enableFormElements:function(b){b.find(c.enableSelector).each(function(){var b=a(this),c=b.is("button")?"html":"val";b.data("ujs:enable-with")&&b[c](b.data("ujs:enable-with")),b.prop("disabled",!1)})},allowAction:function(a){var b=a.data("confirm"),d=!1,e;return b?(c.fire(a,"confirm")&&(d=c.confirm(b),e=c.fire(a,"confirm:complete",[d])),d&&e):!0},blankInputs:function(b,c,d){var e=a(),f,g=c||"input,textarea";return b.find(g).each(function(){f=a(this);if(d?f.val():!f.val())e=e.add(f)}),e.length?e:!1},nonBlankInputs:function(a,b){return c.blankInputs(a,b,!0)},stopEverything:function(b){return a(b.target).trigger("ujs:everythingStopped"),b.stopImmediatePropagation(),!1},callFormSubmitBindings:function(c){var d=c.data("events"),e=!0;return d!==b&&d.submit!==b&&a.each(d.submit,function(a,b){if(typeof b.handler=="function")return e=b.handler(b.data)}),e},disableElement:function(a){a.data("ujs:enable-with",a.html()),a.html(a.data("disable-with")),a.bind("click.railsDisable",function(a){return c.stopEverything(a)})},enableElement:function(a){a.data("ujs:enable-with")!==b&&(a.html(a.data("ujs:enable-with")),a.data("ujs:enable-with",!1)),a.unbind("click.railsDisable")}},a.ajaxPrefilter(function(a,b,d){a.crossDomain||c.CSRFProtection(d)}),a(c.linkDisableSelector).live("ajax:complete",function(){c.enableElement(a(this))}),a(c.linkClickSelector).live("click.rails",function(d){var e=a(this),f=e.data("method"),g=e.data("params");if(!c.allowAction(e))return c.stopEverything(d);e.is(c.linkDisableSelector)&&c.disableElement(e);if(e.data("remote")!==b)return(d.metaKey||d.ctrlKey)&&(!f||f==="GET")&&!g?!0:(c.handleRemote(e),!1);if(e.data("method"))return c.handleMethod(e),!1}),a(c.inputChangeSelector).live("change.rails",function(b){var d=a(this);return c.allowAction(d)?(c.handleRemote(d),!1):c.stopEverything(b)}),a(c.formSubmitSelector).live("submit.rails",function(d){var e=a(this),f=e.data("remote")!==b,g=c.blankInputs(e,c.requiredInputSelector),h=c.nonBlankInputs(e,c.fileInputSelector);if(!c.allowAction(e))return c.stopEverything(d);if(g&&e.attr("novalidate")==b&&c.fire(e,"ajax:aborted:required",[g]))return c.stopEverything(d);if(f)return h?c.fire(e,"ajax:aborted:file",[h]):!a.support.submitBubbles&&c.callFormSubmitBindings(e)===!1?c.stopEverything(d):(c.handleRemote(e),!1);setTimeout(function(){c.disableFormElements(e)},13)}),a(c.formInputClickSelector).live("click.rails",function(b){var d=a(this);if(!c.allowAction(d))return c.stopEverything(b);var e=d.attr("name"),f=e?{name:e,value:d.val()}:null;d.closest("form").data("ujs:submit-button",f)}),a(c.formSubmitSelector).live("ajax:beforeSend.rails",function(b){this==b.target&&c.disableFormElements(a(this))}),a(c.formSubmitSelector).live("ajax:complete.rails",function(b){this==b.target&&c.enableFormElements(a(this))})})(jQuery)