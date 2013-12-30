define(['underscore', 'backbone',
        '/assets/libs/backbone.poller.min'],
  function(_, Backbone, Poller){

  function showNotification(classes, message){
    var flash_template = _.template($("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(6000).fadeOut(800);
  }

	var SCMRepoModel = Backbone.Model.extend({
    idAttribute: "_id",
  });

  var SCMAllRepoCollection = Backbone.Collection.extend({
    model: SCMRepoModel,
    url: "/missing/setting",
    initialize: function(models, options){
      console.debug("Scm options to collection");
      console.debug(options.urls);
      this.urls = options.urls;
      this.url = options.urls.root;
      this.app = options.app;
      this.poller = Poller.get(this, {delay: 1000}); //registered event is main.js
      this.initViews = options.initViews;
    },

    parse: function(response){
      if(response.success){

        if(response.task_status === 'done'){
          console.debug("Got all repos. Stopping poller;");
          showNotification(
              "alert alert-success",
              "Importing your SCM repositories is done."
          );
          this.poller.stop();

          //when we didnt get any repo after polling;
           if(_.isUndefined(response.repos) || _.isEmpty(response.repos)|| _.isNull(response.repos)){
             $("#github-repos").html('<strong>No repositories</strong>');
           }
        }

        if(!_.isUndefined(response.repos) && !_.isEmpty(response.repos) && !_.isNull(response.repos)){
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
    clearAll: function(cb){
      console.debug("Going to clear cache: " + this.urls.clear);
      var jqxhr = $.get(this.urls.clear);
      var that = this;
      jqxhr.success(function(){
        console.debug("Going to repoll content.");
        that.poller.start();
        cb()
      });
    },
    fetchAll: function(update_fn){
      console.debug("#-- [deprecated] Going to re-fill repo cache");
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
                           '<div><i class="icon-info-sign"></i> Can not load your repositories due a connectivity issues.</div>');
          $("#github-repos").html("Connection issues - can not read data from SCM.");
        }
      });
    },
    matchByName: function(search_term){
      var matched_repos = this.filter(function(repo){
        return repo.get("name").toLowerCase().indexOf(search_term) >= 0;
      },
      this);

      return matched_repos;
    }
   });

  return SCMAllRepoCollection;
});
