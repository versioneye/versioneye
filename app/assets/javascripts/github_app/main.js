define(
	['jQuery', 'underscore', 'backbone', 'moment', 'bootstrap_switch',
   'paginator'],
	function($, _, Backbone, moment, BootstrapSwitch, Paginator){

	_.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
      evaluate: /\{\{(.+?)\}\}/g
  };

  function showNotification(classes, message){
    var flash_template = _.template(jQuery("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    }));
  }

  function addRepoLinkLabel(selector, model){
    var url_label_template = _.template(jQuery("#github-repo-urllabel-template").html());
    $(selector).find('.repo-labels').append(url_label_template({
      classes: "label label-info",
      url: model.get("project_url"),
      content: '<i class="icon-home"></i> Project\'s page'
    }));
  }

  function removeRepoLinkLabel(selector){
    $(selector).find('.repo-homepage').remove();
  }

	var GithubRepoModel = Backbone.Model.extend({});
  var GithubRepoCollection = Backbone.Paginator.requestPager.extend({
    model: GithubRepoModel,
    paginator_core: {
      type: 'GET',
      dataType: 'json',
      url: '/user/github_repos'
    },
    paginator_ui: {
      firstPage: 1,
      currentPage: 1,
      perPage: 5
    }, 
    server_api: {
      per_page: function(){return this.perPage;},
      page: function(){return this.currentPage;}
    },
    parse: function(response){
      if(response.success){
        this.totalPages = response.paging.total_pages;
        this.totalRecords = response.paging.total_entries;
        this.currentPage = response.paging.current_page;
        return response.repos;
      } else {
        return []
      }
    }
  });

	var GithubMenuItem = Backbone.Model.extend({});
	var GithubMenuCollection = Backbone.Collection.extend({
		url: "/user/menu/github_repos",
		model: GithubMenuItem
	});

	var GithubRepoSwitchView = Backbone.View.extend({
		template: _.template($("#github-repo-switch-template").html()),
		events: {
			"switch-change .switch" : "onSwitchChange"
		},

		initialize: function(options){
			this.parent = options.parent;
		},

		render: function(){
			this.$el.html(this.template({repo: this.model.toJSON()}));
			return this;
		},

		onSwitchChange: function(ev, switch_data){
      is_switch_active = switch_data.el.parent().bootstrapSwitch("isActive");

      switch_data.el.parents(".github-switch").bootstrapSwitch('setActive', false);

      if(is_switch_active && switch_data.value){
        this.addProject(switch_data.el, switch_data.value);
      } else if (is_switch_active && !switch_data.value) {
        this.removeProject(switch_data.el), switch_data.value;
      } else {
        console.log("Going to drop event of unactive switch.");
        switch_data.el.parents(".github-switch").bootstrapSwitch('setActive', true);
      }
			return false;
		},

		addProject: function(el, data){
			console.log("Adding new project");
	    this.model.save(
        {command: "import"}, 
        {
          beforeSend: function(xhr) {
            xhr.setRequestHeader('X-CSRF-Token',
                                 $('meta[name="csrf-token"]').attr('content'));
          },
          success: this.onAddSuccess,
          error: this.onAddFailure
        });
    },

    onAddSuccess: function(model, xhr, options){
      var selector = "#github-repo-" + model.get("github_id");
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
      var msg = ['<strong> Success! </strong>',
                 'Github project ', model.get('fullname'),
                 ' is now successfully imported.', 
                 'You can now checkout project\'s page to see state of dependencies.'
                 ].join(' ');

      addRepoLinkLabel(selector, model);
      $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
      showNotification("alert alert-success", msg);
      return true;
    },

    onAddFailure: function(model, xhr, options){
      console.log("Failure: Cant import project: " + model.get('fullname'));
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
      $(switch_selector).parents(".github-switch").bootstrapSwitch("setState", false);
      $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
      return false;
    },

		removeProject: function(el, data){
			console.log("Removing selected project.");
      this.model.save(
        {command: "remove"},
        {
          beforeSend: function(xhr) {
            xhr.setRequestHeader('X-CSRF-Token', 
                                 $('meta[name="csrf-token"]').attr('content'));
          },
          success: this.onRemoveSuccess,
          error: this.onRemoveFailure
        }
      );
		},

   onRemoveSuccess: function(model, xhr, options){
      var selector = "#github-repo-" + model.get("github_id");
      var msg = [
        '<strong>Success!</strong>',
        'Github project ', model.get('fullname'),
        ' is now successfully removed from your projects.'
      ].join(' ');

      removeRepoLinkLabel(selector);
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
      $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
      showNotification("alert alert-succes", msg);

      return true;
   },
   onRemoveFailure: function(model, xhr, options){
      var msg = "Fail: Cant remove project";
      var switch_selector = "#github-repo-switch-" + model.get('github_id');

      $(switch_selector).parents(".github-switch").bootstrapSwitch('setState', true);
      $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
      showNotification("alert alert-warning", msg);

      return false;
    },
	});

	var GithubRepoLabelView = Backbone.View.extend({
		template: _.template($("#github-repo-label-template").html()),

		initialize: function(options){
			this.parent = options.parent;
		},
		render: function(){

			var repo = this.model.toJSON();
			var type_label_template = _.template('<strong>{{= type}}</strong>');
			var url_template = _.template('<a href="{{= url}}" >{{= content }}</a>');

			var labels = [];
			var timeago = moment(repo.updated_at).fromNow();
			var label_models = [
				{classes: "repo-type label label-warning",
				 content: type_label_template({
				 	type: (repo.private) ? "private": "public"
				 })
				}, {
				 classes: "repo-language label label-info",
				 content: repo.language
				}, {
				 classes: "repo-updated label",
				 content: "<strong>updated: &nbsp;</strong>" + timeago
				}
			]

			if(repo.project_url){
				var label_content = this.template({
					classes: "label label-info",
					content: '<i class="icon-white icon-home"></i>Projects page'
				});
				var url_label = url_template({
					url: repo.project_url,
					content: label_content
				});
				label_models.push({
					classes: "repo-homepage",
					content: url_label
				});
			}

			var that = this;
			_.each(label_models, function(label_model){
				labels.push(that.template(label_model));
			});

			this.$el.html(labels.join(' '));
			return this;
		}
	});

	var GithubRepoItemView = Backbone.View.extend({
		template: _.template($("#github-repo-info-template").html()),
		render: function(){

			var switch_view = new GithubRepoSwitchView({model: this.model});
			var label_view = new GithubRepoLabelView({model: this.model});

			var repo_container = this.template({
				repo: this.model.toJSON()
			});
			this.$el.html(repo_container);
			this.$el.find(".repo-switch").html(switch_view.render().el);
			this.$el.find(".repo-labels").html(label_view.render().el);
			return this;
		}
	});
	
  var GithubMenuView =  Backbone.View.extend({
    el: "#github-menu",
    template: _.template($("#github-menu-template").html()),
	  item_template: _.template($("#github-menu-item-template").html()),
    initialize: function(){
      this.collection.bind('change', this.render, this);
      this.collection.on('all', this.render, this);
    }, 
    render: function(){
      console.log("Rendering menu...");
      $(this.el).html(this.template({}));

      $(this.el).find("#github-menu-orgs").empty();
      this.collection.each(function(org){
      	$(this.el).find("#github-menu-orgs").append(
      		this.item_template({org: org.toJSON()})
      	);
      }, this)
      return this;
    }
  });
  
  var GithubRepoView = Backbone.View.extend({
		el: '#github-repos',
    initialize: function(){
      var repos = this.collection;
      repos.on('add', this.addItem, this);
      repos.on('reset', this.resetView, this);
      //repos.on('all', this.render, this);
      //repos.pager();
    },
		resetView: function(){
      console.debug("Resetting repo view");
      $("#github-loader").remove();
      $("#github-repos").empty(); 
			return false;
		},
		addItem : function(model){
			var itemview = new GithubRepoItemView({model: model});
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
			$("#github-repos").append(itemview.render().el);
			$(switch_selector).parent().bootstrapSwitch(); 
	    $("#github-loader").remove();
  }
	});

	var GithubLoadingView = Backbone.View.extend({
		el: "#github-repos",
		template: _.template($("#github-loading-template").html()),
		render: function(){
			$(this.el).html(this.template({
				classes: "alert alert-info",
				message: "Please wait, we are importing data from GitHub."
			}));
		}
	});

  var GithubPaginationView = Backbone.View.extend({
    events: {
      "click .btn-pagination-next": "loadMore"
    },
    template: _.template($("#github-pagination-template").html()),
    initialize: function () {
      this.collection.on('sync', this.render, this);
      $('#github-pagination').html(this.$el);
    },
    render: function(){
      $(this.el).html(this.template({
        paging: {
          currentPage: this.collection.currentPage,
          totalPages: this.collection.totalPages
        }
      }));
    },
    loadMore: function(e){
      console.debug("Showing more results.");
      this.collection.requestNextPage();
      return false;
    }
  });

  var prev_org_id = null;
  var user_repos = new GithubRepoCollection();
  var repo_view = new GithubRepoView({collection: user_repos});
  var pagination_view = new GithubPaginationView({collection: user_repos});
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

      $('.github-switch').bootstrapSwitch('destroy');
      $('.github-switch').remove();

			var loader_view = new GithubLoadingView();
			loader_view.render();

			var menu_items = new GithubMenuCollection();
		  var menu_view = new GithubMenuView({collection: menu_items});
      menu_items.fetch({});
 
      user_repos.fetch({
        data: {org_id: org_id},
        cache: false,
        error: function(repos, response, options){
          showNotification(
            "alert alert-warning",
            "Cant load repos: " + response);
        }
      });
		}
	});

	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
	}};
});
