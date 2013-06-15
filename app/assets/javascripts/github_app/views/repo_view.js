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
      this.collection.on('change', this.onChange, this);
      this.collection.on('sort', this.resetView, this);
    },

    render: function(){
      this.collection.each(function(repo){
        this.addItem(repo);
      }, this);
    },
		resetView: function(){
      console.debug("Resetting repo view");
      $('.github-switch').bootstrapSwitch('destroy');
      $('.github-switch').remove();
      $("#github-loader").remove();
      $("#github-repos").empty();
      this.render();
			return false;
		},

    addAll: function(repos){
      console.log("Fired all event on GithubRepoView");
    },
		addItem : function(model){
      console.log("Going to render item: " + model.get('fullname'));
			var itemview = new GithubRepoItemView({model: model});
  		$("#github-repos").append(itemview.render().el);
  
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
			$(switch_selector).parent().bootstrapSwitch();
    }, 
    onChange: function(){
      console.debug("RepoView catched change on collection.");
    }
	});

	return GithubRepoView;
});
