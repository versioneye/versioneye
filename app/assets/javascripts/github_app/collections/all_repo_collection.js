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
    },
    fetchAll: function(update_fn){
      this.fetch({
        cache: false,
        reset: true,
        success: function(repos, response, options){
          if(repos.length == 0){
            //TODO: write as template
            $("#github-repos").html("You and your's organizations dont have any Github repositories.");
            return false
          }
         if(_.isFunction(update_fn)){update_fn(repos);}
        },
        error: function(repos, response, options){
          showNotification("alert alert-error", 
                           '<div><i class="icon-info-sign"></i> Cant load your repositoiries due a connectivity issues.</div>');
          $("#github-repos").html("You dont have any github repos or we just cant imported.");
        }
      });
     }
   });

  return GithubAllRepoCollection;
});
