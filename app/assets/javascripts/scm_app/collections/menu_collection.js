define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var SCMMenuItem = Backbone.Model.extend({});
	var SCMMenuCollection = Backbone.Collection.extend({
		url: "/urls/menu", 
		model: SCMMenuItem,

    initialize: function(models, options){
      this.url = options.urls.menu;
    }
	});


  return SCMMenuCollection;
});
