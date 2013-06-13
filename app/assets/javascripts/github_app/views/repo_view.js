define(['underscore', 'backbone',
	   '/assets/github_app/views/repo_item_view'],
  function(_, Backbone, GithubRepoItemView){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var GithubRepoView = Backbone.View.extend({
		el: '#github-repos',
    initialize: function(){
      var repos = this.collection;
      repos.on('add', this.addItem, this);
      repos.on('reset', this.resetView, this);
    },
		resetView: function(){
      console.debug("Resetting repo view");
      $('.github-switch').bootstrapSwitch('destroy');
      $('.github-switch').remove();
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

	return GithubRepoView;
});
