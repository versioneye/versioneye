define(
	['underscore', 'backbone', 'moment',
   '/assets/scm_app/views/loading_view',
   '/assets/scm_app/views/menu_view',
   '/assets/scm_app/views/repo_view',
   '/assets/scm_app/views/pagination_view',
   '/assets/scm_app/collections/all_repo_collection',
   '/assets/scm_app/collections/repo_collection',
   '/assets/scm_app/collections/menu_collection'],
	function(_, Backbone, moment,
            SCMLoadingView, SCMMenuView, SCMRepoView,
            SCMPaginationView, SCMAllRepoCollection,
            SCMRepoCollection, SCMMenuCollection){


  var AppRouter = Backbone.Router.extend({
    initialize: function(options){
      this.app = options.app;
    },
		routes: {
			'user': 'showRepos',
			'org/:org_id': 'showRepos',
			'*path': 'showDefaultRepos'
		},
    showDefaultRepos: function(){
			var loader_view = new SCMLoadingView();
			loader_view.render();
      this.app.allRepos.poller.start();
    },
		showRepos: function(org_id){
      var all_repos =  this.app.allRepos;
      var current_repos = this.app.currentRepos;

      if(_.isNaN(org_id) || _.isUndefined(org_id)){
        org_id = get_default_org(all_repos);
      }
      if(current_repos.org_id !== org_id){
        console.log("Org id changed - cleaning up & resetting view.");
        this.app.currentRepos.org_id = org_id;
        this.app.currentRepos.reset();
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

  var SCMApp = function(app_options){
    this.options = app_options || {};

    this.showNotification = function(classes, message){
      var flash_template = _.template($("#github-notification-template").html());
      $(".flash-container").html(flash_template({
        classes: classes,
        content: message
      })).fadeIn(400).delay(6000).fadeOut(800);
    };

    this.get_default_org = function(repos){
        var repo = repos.first();
        return repo.get('user_login');
    };

    //allRepos ~ client-side cache
    this.allRepos = new SCMAllRepoCollection([],
      {
        app: this,
        urls: this.options.repo_urls
      }
    );

    this.currentRepos   = new SCMRepoCollection([], {allRepos: this.allRepos}); //includes only repos for current view
    this.repoView       = new SCMRepoView({
      app: this,
      collection: this.currentRepos
    });
    this.paginationView = new SCMPaginationView({
      app : this,
      collection: Backbone.Collection.extend({}),
      currentRepos: this.currentRepos
    });

    this.menuItems      = new SCMMenuCollection([], {urls: this.options.repo_urls});
    this.menuView       = new SCMMenuView({
      app: this,
      collection: this.menuItems,
      currentRepos: this.currentRepos,
      allRepos: this.allRepos,
      repoView: this.repoView
    });

    this.initViews = function(repos){
      this.menuItems.fetch({});
      if(_.isNaN(this.currentRepos.org_id) || _.isUndefined(this.currentRepos.org_id)){
        this.currentRepos.org_id = this.get_default_org(repos);
      }
      console.debug("Initializing view with org-id: " + this.currentRepos.org_id);
      this.currentRepos.reset();
      this.currentRepos.perPage = 10;
      this.currentRepos.appendNextPage(0);
      this.paginationView.render();
    };

    this.start = function(){
      console.log("Running SCM app with options: ");
      console.debug(this.options);

      // -- run app
      var thisApp = this;
      var app_router = new AppRouter({app: this});
      Backbone.history.start();

      this.allRepos.poller.on('success', function(repos){
        console.info('another successful fetch!');
        var notification_template = _.template($("#github-notification-template").html());
        var loader_notification = $("#github-loader-notification");
        loader_notification.empty();

        if(_.isUndefined(repos) || _.isEmpty(repos)){
          loader_notification.html('Still reading data from SCM .');
        }

        if(!_.isUndefined(repos)  && !_.isNull(repos) && !_.isEmpty(repos) && repos.length > 0){
          if(thisApp.currentRepos.length < 10){
            //change view only when it's smaller than per_page number;
            console.debug("Going to re=render page;");
            thisApp.initViews(repos);
          }
          //update loader notification
          if(repos.at(0).get('task_status') === 'done'){
            loader_notification.html([
              'Got ',  repos.length, 'repositories.'
            ].join(' '));

            thisApp.initViews(repos); // re-render again when importing ready to get pagination right
          } else {
            loader_notification.html([
              '<i class = "icon-spinner icon-spin"></i>',
              ' Please wait. We are still reading data from the GitHub API. Imported ',  repos.length, 'repositories'
              ].join(' ')
            );
          }
        }
      }); //poller end
    };

    return this;
  }





	return SCMApp;
});
