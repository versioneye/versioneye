define(
	['underscore', 'backbone', 'moment',
   '/assets/github_app/views/loading_view',
   '/assets/github_app/views/menu_view',
   '/assets/github_app/views/repo_view',
   '/assets/github_app/views/pagination_view',
   '/assets/github_app/collections/all_repo_collection',
   '/assets/github_app/collections/repo_collection',
   '/assets/github_app/collections/menu_collection'],
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

  function fetchAll(cb){
    var jqxhr = $.ajax("/user/github/fetch_all")
      .done(function(data, status, jqxhr){
        if(data.changed){
          all_repos.reset();
          showNotification(
            "alert alert-info",
            "We just reimported all your repositories successfully!"
          );
          all_repos.fetchAll();
        } else {
          showNotification(
            "alert alert-info",
            "We could not detect any changes on your Github repositories."
          );
          console.log("No changes for repos - i'll wait and poll again.");
        }
      })
      .always(cb);
  }

  function checkChanges(show_all){
    if(_.isUndefined(show_all)){
      show_all = false;
    }
    var jqxhr = $.ajax("/user/poll/github_repos")
      .done(function(data, status, jqxhr){
        if(data.changed){
          all_repos.clearAll(initViews);
          showNotification(
            "alert alert-info",
            "We detected some changes on your Github repositories and updated the view here."
          );
          all_repos.fetchAll(initViews);
        } else {
          if(show_all == true){
            showNotification(
              "alert alert-info",
              "We could not detect any changes on your Github repositories."
            );
          }
          console.log("No changes for repos - i'll wait and poll again.");
        }
      });
  }

  function pollChanges(timeout){
    timeout = timeout || 15000;
    console.debug("Going to check changes. After waiting: " + timeout);
    setTimeout(checkChanges, timeout);
  }

  //TODO: refactor to GithubApp namespace
  //TODO: keep data in browser DB
  var all_repos       = new GithubAllRepoCollection(); //includes all repos ~ client-side cache
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


  var have_checked_cache = false;

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


    if(!_.isUndefined(repos)  && !_.isNull(repos) && !_.isEmpty(repos) && repos.length > 0){
      if(repos.length < current_repos.perPage){
        //change view only when it's smaller than per_page number;
        initViews(repos);
      }

      loader_notification.html([
          'Got ',  repos.length, 'repositories'
      ].join(' ')
      );
    } else {
      loader_notification.html('Still no data. Going to ping soon again');
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
        //all_repos.fetchAll(initViews);
        all_repos.poller.start();
      }
    }
	});

	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
    setTimeout(pollChanges, 15000);
  }};
});
