define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};


	var GithubRepoLabelView = Backbone.View.extend({
		className: "repo-labels",
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
      var commit_timeago = moment(repo.updated_at).fromNow();
      var cached_timeago = moment(repo.cached_at).fromNow();

			var label_models = [
				{classes: "repo-type label label-warning",
				 content: type_label_template({
				 	type: (repo.private) ? "private": "public"
				 })
				}, {
				 classes: "repo-language label label-info",
				 content: repo.language || "language is not specified"
				}, {
          classes: "repo-pushed label",
          content: "last commit:&nbsp;" + commit_timeago
        }, {
          classes: "repo-pushed label",
          content: "last import:&nbsp;" + cached_timeago
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

  return GithubRepoLabelView;

});
