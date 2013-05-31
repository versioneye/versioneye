define(
	['jQuery', 'underscore', 'backbone', 'moment', 'bootstrap_switch'],
	function($, _, Backbone, moment){

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
    $(selector).find('.repo-labels').append({
      classes: "label label-info",
      url: model.get("project_url"),
      content: '<i class="icon-home"></i> Project\'s page'
    });
  }

  function removeRepoLinkLabel(selector){
    $(selector).find('.repo-homepage').remove();  
  }

	var GithubRepoModel = Backbone.Model.extend({});

	var GithubRepoCollection = Backbone.Collection.extend({
		url: "/user/github_repos",
		model: GithubRepoModel,
		parse: function(response){
			if(response.success){
				return response.repos;
			} else {
				return [];
			}
		}
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
      console.debug(switch_data);
      is_switch_active = switch_data.el.parent().bootstrapSwitch("isActive");
      
      switch_data.el.parent().bootstrapSwitch('setActive', false);

      if(is_switch_active && switch_data.value){
        this.addProject(switch_data.el, switch_data.value);
      } else if (is_switch_active && !switch_data.value) {
        this.removeProject(switch_data.el), switch_data.value;
      } else {
        console.log("Going to drop event of unactive switch.")
      }
			return false;
		},

		addProject: function(el, data){
			console.log("Adding new project");
	    el.parent().bootstrapSwitch('setActive', false);
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
      var switch_selector = "github-repo-switch-" + model.get('github_id');
      var msg = ['<strong> Success! </strong>',
                 'Github project ', model.get('fullname'),
                 ' is now successfully imported.', 
                 'You can now checkout project\'s page to see state of dependencies.'
                 ].join(' ');

      addRepoLinkLabel(selector, model);
      $(switch_selector).parent().bootstrapSwitch('setActive', true);
      showNotification("alert alert-success", msg);
    },

    onAddFailure: function(model, xhr, options){
      console.log("Failure: Cant import project: " + model.get('fullname'));
      var switch_selector = "github-repo-switch-" + model.get('github_id');
      $(switch_selector).parent().bootstrapSwitch("setState", false);
      $(switch_selector).parent().bootstrapSwitch('setActive', true);
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
      var switch_selector = "github-repo-switch-" + model.get('github_id');
      $(switch_selector).parent().bootstrapSwitch('setActive', true);
      showNotification("alert alert-succes", msg);
   },
   onRemoveFailure: function(model, xhr, options){
      console.log("Fail: Cant remove project");
      var switch_selector = "github-repo-switch-" + model.get('github_id');
      $(switch_selector).parent().bootstrapSwitch('setState', true);
      $(switch_selector).parent().bootstrapSwitch('setActive', true);
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
	var GithubRepoView = Backbone.View.extend({
		el: '#github-repos',

		render: function(){
			this.$el.empty();
			this.collection.each(this.addItem);

			$(".switch").bootstrapSwitch();
			return this;
		},
		addItem : function(model){
			var itemview = new GithubRepoItemView({model: model});
			$("#github-repos").append(itemview.render().el);
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

	var AppRouter = Backbone.Router.extend({
		routes: {
			'user': 'showUserRepos',
			'org': 'showOrgRepos',
			'*path': 'showUserRepos'
		},
		showUserRepos: function(){
			console.log("going to show repos for user");
			var loader_view = new GithubLoadingView();
			loader_view.render();
			//load repo data
			var user_repos = new GithubRepoCollection();
			user_repos.fetch({
				data: {page: 1},
				success:  function(repos, response, options){
					var repo_view = new GithubRepoView({collection: repos});
					repo_view.render();
				}
			});
		},
		showOrgRepos: function(){
			console.log("going to show repos for org");
		}

	});


	return {init : function(){
		console.log("Running github app");
		var app_router = new AppRouter();
		Backbone.history.start();
	}};
});
