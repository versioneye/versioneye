define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var SCMMenuItem = Backbone.Model.extend({});
	var SCMMenuCollection = Backbone.Collection.extend({
		url: "/user/bitbucket/menu",
		model: SCMMenuItem
	});


  return SCMMenuCollection;
});
