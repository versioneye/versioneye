define(
	['jQuery', 'underscore', 'backbone', 'moment', 'bootstrap_switch',
   '/assets/github_app/views/loading_view',
   '/assets/github_app/views/menu_view',
   '/assets/github_app/views/repo_view',
   '/assets/github_app/views/pagination_view',
   '/assets/github_app/collections/all_repo_collection',
   '/assets/github_app/collections/repo_collection',
   '/assets/github_app/collections/menu_collection'],
	function($, _, Backbone, moment, BootstrapSwitch,
            GithubLoadingView, GithubMenuView, GithubRepoView,
            GithubPaginationView, GithubAllRepoCollection, 
            GithubRepoCollection, GithubMenuCollection){

  function showNotification(classes, message){
    var flash_template = _.template(jQuery("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(3000).fadeOut(800);

  }

  function update_all_repos(update_fn){
    all_repos.fetch({
      cache: false,
      reset: true,
      success: function(repos, response, options){
        if(repos.length == 0){
          //TODO: write as template
          $("#github-repos").html("You and your's organizations dont have any Github repositories.");
          return false
        }
        console.debug("Got repos: " + repos.length);
        update_fn();
      },
      error: function(repos, response, options){
        showNotification("alert alert-error", 
                         '<div><i class="icon-info-sign"></i> Cant load your repositoiries due a connectivity issues.</div>');
        $("#github-repos").html("You dont have any github repos or we just cant imported.");
      }
    });
  }

  function pollChanges(){
    var jqxhr = $.ajax("/user/poll/github_repos")
        .done(function(data, status, jqxhr){
          if(data.changed){
            showNotification(
              "alert alert-info",
              "Detected changes on your Github repos - updated view."
            );
            all_repos.reset();
            update_all_repos();
          } else {
            console.log("No changes for repos - i'll wait and poll again.");
          }
        })
        .always(function(){ setTimeout(pollChanges, 30000); });
  }

  var all_repos       = new GithubAllRepoCollection(); //includes all repos
  var current_repos   = new GithubRepoCollection(); //includes only repos for current view
  var repo_view       = new GithubRepoView({collection: current_repos});
  //var pagination_view = new GithubPaginationView({collection: current_repos});
  var menu_items      = new GithubMenuCollection();
  var menu_view       = new GithubMenuView({collection: menu_items});

  var filter_by_org = function(repo){
    return repo.get("owner_login") == current_repos.org_id;
  }

  var get_default_org = function(repos){
    return repos.first().get('user_login');
  }

  var AppRouter = Backbone.Router.extend({
		routes: {
			'user': 'showRepos',
			'org/:org_id': 'showRepos',
      'sort-by/:field/:order': 'sortRepos',
			'*path': 'showDefaultRepos'
		},
    showDefaultRepos: function(){
 
			var loader_view = new GithubLoadingView();
			loader_view.render();
      menu_items.fetch({});
      update_all_repos(function(){
        current_repos.org_id = get_default_org(all_repos);
        current_repos.set(all_repos.filter(filter_by_org));
      });
    },
		showRepos: function(org_id){
      org_id = (_.isNull(org_id)) ? get_default_org(all_repos) : org_id;
      if(current_repos.org_id !== org_id){
        console.log("Org id changed - cleaning up & resetting view.");
        current_repos.org_id = org_id;
        current_repos.reset();
      }
			console.log("going to show repos for: " + org_id);
      console.log("all repos count: " + all_repos.length);
	    current_repos.set(all_repos.filter(filter_by_org));
      console.log("Size of current_repos:" + current_repos.length);
	  }, 

    sortRepos: function(field, order){
      console.debug("Sorting by " + field + " order: " + order);
    }
	});

	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
	  setTimeout(pollChanges, 30000); //start polling in 30secs
  }};
});
