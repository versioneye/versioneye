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
    })).fadeIn(400).delay(6000).fadeOut(800);

  }
  
  function pollChanges(){
    var jqxhr = $.ajax("/user/poll/github_repos")
        .done(function(data, status, jqxhr){
          if(data.changed){
            showNotification(
              "alert alert-info",
              "Detected changes on your Github repos - updated view."
            );
            all_repos.fetchAll(initViews);
          } else {
            console.log("No changes for repos - i'll wait and poll again.");
          }
        })
        .always(function(){ setTimeout(pollChanges, 30000); });
  }

  //TODO: refactor to GithubApp namespace
  var all_repos       = new GithubAllRepoCollection(); //includes all repos
  var current_repos   = new GithubRepoCollection([], {allRepos: all_repos}); //includes only repos for current view
  var repo_view       = new GithubRepoView({collection: current_repos});
  var pagination_view = new GithubPaginationView({
                              collection: Backbone.Collection.extend({}),      
                              currentRepos: current_repos
                        });
  var menu_items      = new GithubMenuCollection();
  var menu_view       = new GithubMenuView({
                          collection: menu_items, 
                          currentRepos: current_repos,
                          allRepos: all_repos
                        });

  var get_default_org = function(repos){
    var repo = repos.first();
    return repo.get('user_login');
  }
  
  var initViews = function(repos){
    menu_items.fetch({});
    if(_.isNaN(current_repos.org_id) || _.isUndefined(current_repos.org_id)){
      current_repos.org_id = get_default_org(repos);
    }
    console.debug("Initializing view with org-id: " + current_repos.org_id)
    current_repos.perPage = 5;
    current_repos.appendNextPage(0);
    pagination_view.render();
  };

  var AppRouter = Backbone.Router.extend({
		routes: {
			'user': 'showRepos',
			'org/:org_id': 'showRepos',
			'*path': 'showDefaultRepos'
		},
    showDefaultRepos: function(){
			var loader_view = new GithubLoadingView();
			loader_view.render();
      all_repos.fetchAll(initViews);
    },
		showRepos: function(org_id){
      if(_.isNaN(org_id) || _.isUndefined(org_id)){
        org_id = get_default_org(all_repos);
      }

      if(current_repos.org_id !== org_id){
        console.log("Org id changed - cleaning up & resetting view.");
        current_repos.org_id = org_id;
        current_repos.reset();
      }
			console.log("going to show repos for: " + org_id);
      if(all_repos.length){
	      current_repos.appendNextPage(0);
      } else {
        all_repos.fetchAll(initViews);
      }
    } 
	});

	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
	  setTimeout(pollChanges, 30000); //start polling in 30secs
  }};
});
