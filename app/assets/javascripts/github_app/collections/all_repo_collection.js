define(['underscore', 'backbone'],
  function(_, Backbone){

	var GithubRepoModel = Backbone.Model.extend({
    urlRoot: "/user/github_repos"
  });
  var GithubAllRepoCollection = Backbone.Collection.extend({
    model: GithubRepoModel,
    url: "/user/github_repos",
    parse: function(response){
      if(response.success){
        if(response.repos.length){
          console.log("Got " + response.repos.length + " repos.");
          return response.repos;
        } else {
          console.log("Got no repos;");
          return [];
        }

      } else {
        console.log("Backend issue while fetching repos.");
        return [];
      }
    }
  });

  return GithubAllRepoCollection;
});
