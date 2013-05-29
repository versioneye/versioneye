define(
	['jQuery', 'underscore', 'backbone', 'moment', 'bootstrap_switch'],
	function($, _, Backbone, moment){

	_.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
      evaluate: /\{\{(.+?)\}\}/g
    };

	var GithubRepoModel = Backbone.Model.extend({

	});

	var GithubRepoCollection = Backbone.Collection.extend({
		url: "/user/projects/github_repos",
		model: GithubRepoModel,
		parse: function(response){
			console.log(response);
			if(response.success){
				return response.repos;
			} else {
				return [];
			}
		}
	});

	var GithubRepoSwitchView = Backbone.View.extend({
		el: $('#github-repos'),
		template: _.template($("#github-repo-switch-template").html()),

		events: {
			'switch-change .switch': 'on_switch_change'
		},

		render_str: function(model){
			this.model = model || this.model;
			return this.template({repo: this.model.toJSON()});
		},
		on_switch_change: function(ev){
			//TODO: finish it - and it runs ~27times;
			console.log(ev.target);
			
			ev.stopPropagation();
        	ev.stopImmediatePropagation();

			return false;
		}
	});

	var GithubRepoLabelView = Backbone.View.extend({
		template: _.template($("#github-repo-label-template").html()),

		render_str: function(model){
			return this.template(model);
		},

		render_labels: function(model){
			this.model = model || this.model;

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

			return labels;
		}
	});

	var GithubRepoInfoView = Backbone.View.extend({
		template: _.template($("#github-repo-info-template").html()),

		render_str: function(model){
			this.model = model || this.model;
			var switch_view = new GithubRepoSwitchView({model: this.model});
			var label_view = new GithubRepoLabelView({model: this.model});

			return  this.template({
				repo: this.model.toJSON(),
				labels: label_view.render_labels().join('\n'),
				github_switch: switch_view.render_str()
			});
		}
	});
	var GithubRepoView = Backbone.View.extend({
		el: "#github-repos",
		template: _.template($("#github-table-template").html()),

		render: function(){
			console.log(this.collection.toJSON());
			$(this.el).html(this.template({}));
			var table_el = $(this.el).find("tbody");
			var item_view = new GithubRepoInfoView({});

			this.collection.each(function(repo_model){
				table_el.append(item_view.render_str(repo_model));
			});

			$(".switch").bootstrapSwitch();

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