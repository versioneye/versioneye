define(['underscore', 'backbone'],
  function(_, Backbone){

  function showNotification(classes, message){
    var flash_template = _.template(jQuery("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(6000).fadeOut(800);
  }
  

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
            var no_repo_template = _.template($("#github-no-repo-template").html());
            $("#github-repos").html(no_repo_template({}));
            return false
          }
         if(_.isFunction(update_fn)){update_fn(repos);}
        },
        error: function(repos, response, options){
          showNotification("alert alert-error",
                           '<div><i class="icon-info-sign"></i> Cant load your repositoiries due a connectivity issues.</div>');
          $("#github-repos").html("Connection issues - cant read data from Github.");
        }
      });
    },
    matchByName: function(search_term){
      var matched_repos = this.filter(function(repo){
        return repo.get("name").indexOf(search_term) >= 0;
      },
      this);

      return matched_repos;
    }
   });

  return GithubAllRepoCollection;
});
