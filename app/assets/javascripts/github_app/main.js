define(
	['jQuery', 'underscore', 'backbone', 'moment', 'bootstrap_switch','paginator',
   '/assets/github_app/views/loading_view',
   '/assets/github_app/views/menu_view',
   '/assets/github_app/views/repo_view',
   '/assets/github_app/views/pagination_view',
   '/assets/github_app/collections/repo_collection',
   '/assets/github_app/collections/menu_collection'],
	function($, _, Backbone, moment, BootstrapSwitch, Paginator,
            GithubLoadingView, GithubMenuView, GithubRepoView,
            GithubPaginationView, GithubRepoCollection, GithubMenuCollection){



  function pollChanges(){
    var jqxhr = $.ajax("/user/poll/github_repos")
        .done(function(data, status, jqxhr){
          if(data.changed){
            showNotification(
              "alert alert-info",
              "Detected changes on your Github repos - updated view."
            );
            user_repos.reset();
            update_user_repos();
          } else {
            console.log("No changes for repos - i'll wait and poll again.");
          }
        })
        .always(function(){
                  setTimeout(pollChanges, 10000);
        });
  }

  function showNotification(classes, message){
    var flash_template = _.template(jQuery("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(3000).fadeOut(800);

  }
  function update_user_repos(){
    user_repos.fetch({
      data: {org_id: prev_org_id},
      cache: false,
      error: function(repos, response, options){
        showNotification(
          "alert alert-warning",
          "Cant load repos: " + response);
      }
    });
  }
  var prev_org_id = null;
  var user_repos = new GithubRepoCollection();
  var repo_view = new GithubRepoView({collection: user_repos});
  var pagination_view = new GithubPaginationView({collection: user_repos});
  var menu_items = new GithubMenuCollection();
  var menu_view = new GithubMenuView({collection: menu_items});
  
  var AppRouter = Backbone.Router.extend({
		routes: {
			'user': 'showRepos',
			'org/:org_id': 'showRepos',
			'*path': 'showRepos'
		},
		showRepos: function(org_id){
      org_id = (_.isNull(org_id)) ? "user" : org_id;
      if(prev_org_id !== org_id){
        console.log("Org id changed - cleaning up & reseting pager.");
        user_repos.reset();
        user_repos.currentPage = 1;
        prev_org_id = org_id;
      }
			console.log("going to show repos for: " + org_id);

			var loader_view = new GithubLoadingView();
			loader_view.render();

      menu_items.fetch({});
      update_user_repos();
		}
	});

	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
    setTimeout(pollChanges, 1000);
	}};
});
