define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var GithubMenuItem = Backbone.Model.extend({});
	var GithubMenuCollection = Backbone.Collection.extend({
		url: "/user/menu/github_repos",
		model: GithubMenuItem
	});


  return GithubMenuCollection;
});