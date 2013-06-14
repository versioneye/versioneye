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
      this.collection.on('all', this.addAll, this);
      this.collection.on('add', this.addItem, this);
      this.collection.on('reset', this.resetView, this);
    },

		resetView: function(){
      console.debug("Resetting repo view");
      $('.github-switch').bootstrapSwitch('destroy');
      $('.github-switch').remove();
      $("#github-loader").remove();
      $("#github-repos").empty();
			return false;
		},
    addAll: function(repos){
      console.log("Fired all event on GithubRepoView");
    },
		addItem : function(model){
      console.log("Going to render item: " + model.toJSON());
			var itemview = new GithubRepoItemView({model: model});
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
			$("#github-repos").append(itemview.render().el);
			$(switch_selector).parent().bootstrapSwitch();
	    $("#github-loader").remove();
    }
	});

	return GithubRepoView;
});
