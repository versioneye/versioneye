define(['underscore', 'backbone'],
  function(_, Backbone){

	var GithubRepoModel = Backbone.Model.extend({
    urlRoot: "/user/github_repos"
  });
  var GithubRepoCollection = Backbone.Collection.extend({
    model: GithubRepoModel
  });

  return GithubRepoCollection;
});
