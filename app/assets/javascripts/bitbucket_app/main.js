define(
	['underscore', 'backbone', 'moment',
   '/assets/bitbucket_app/views/loading_view',
   '/assets/bitbucket_app/views/menu_view',
   '/assets/bitbucket_app/views/repo_view',
   '/assets/bitbucket_app/views/pagination_view',
   '/assets/bitbucket_app/collections/all_repo_collection',
   '/assets/bitbucket_app/collections/repo_collection',
   '/assets/bitbucket_app/collections/menu_collection'],
	function(_, Backbone, moment,
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


  //TODO: refactor to GithubApp namespace
  //TODO: keep data in browser DB
  var all_repos       = new GithubAllRepoCollection({}); //includes all repos ~ client-side cache
  all_repos.showNotification = showNotification;
  all_repos.initViews = initViews;

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
                          allRepos: all_repos,
                          repoView: repo_view
                        });


  //var have_checked_cache = false;

  var get_default_org = function(repos){
    var repo = repos.first();
    return repo.get('user_login');
  }

  var initViews = function(repos){
    menu_items.fetch({});
    if(_.isNaN(current_repos.org_id) || _.isUndefined(current_repos.org_id)){
      current_repos.org_id = get_default_org(repos);
    }
    console.debug("Initializing view with org-id: " + current_repos.org_id);
    current_repos.reset();
    current_repos.perPage = 10;
    current_repos.appendNextPage(0);
    pagination_view.render();
  };

  all_repos.poller.on('success', function(repos){
    console.info('another successful fetch!');
    var notification_template = _.template($("#github-notification-template").html());
    var loader_notification = $("#github-loader-notification");
    loader_notification.empty();
    if(_.isUndefined(repos) || _.isEmpty(repos)){
      loader_notification.html([
            'Still reading data from Github .'
        ].join(' '));
    }

    if(!_.isUndefined(repos)  && !_.isNull(repos) && !_.isEmpty(repos) && repos.length > 0){
      if(current_repos.length < 10){
        //change view only when it's smaller than per_page number;
        console.debug("Going to re=render page;");
        initViews(repos);
      }
      //update loader notification
      if(repos.at(0).get('task_status') === 'done'){
        loader_notification.html([
            'Got ',  repos.length, 'repositories.'
        ].join(' '));

        initViews(repos); // re-render again when importing ready to get pagination right
      } else {
        loader_notification.html([
            '<i class = "icon-spinner icon-spin"></i>',
            ' Please wait. We are still reading data from the GitHub API. Imported ',  repos.length, 'repositories'
        ].join(' ')
        );
      }
    }

    return true;
  });


  var AppRouter = Backbone.Router.extend({
		routes: {
			'user': 'showRepos',
			'org/:org_id': 'showRepos',
			'*path': 'showDefaultRepos'
		},
    showDefaultRepos: function(){
			var loader_view = new GithubLoadingView();
			loader_view.render();
      all_repos.poller.start();
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
      if(all_repos.length && !_.isEmpty(all_repos.first().toJSON())){
        console.debug("All_repos still have some repos: " + all_repos.length);
       	current_repos.appendNextPage(0);
      } else {
        all_repos.poller.start();
      }
    }
	});

	return {init : function(){
		console.log("Running bitbucket app");
		var app_router = new AppRouter();
		Backbone.history.start();
  }};
});
