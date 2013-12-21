define(['underscore', 'backbone',
	   '/assets/scm_app/views/repo_item_view'],
  function(_, Backbone, SCMRepoItemView){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var SCMRepoView = Backbone.View.extend({
		el: '#github-repos',
    initialize: function(options){
      this.app = options.app;
      this.collection.on('add', this.addItem, this);
      this.collection.on('reset', this.resetView, this);
      this.collection.on('change', this.onChange, this);
      this.collection.on('sort', this.render, this);
    },

    render: function(){
      console.log("Rendering all items in RepoCollection");
      $('.onoffswitch').remove();
      $("#github-repos").empty();

      this.collection.each(function(repo){
        this.addItem(repo);
      }, this);
    },
		resetView: function(){
      console.debug("Resetting repo view");
      $('.onoffswitch').remove();
      $("#github-loader").remove();
      $("#github-repos").empty();
			return false;
		},

    addAll: function(repos){
      console.log("Fired all event on SCMRepoView");
    },
		addItem : function(model){
      console.log("Going to render item: " + model.get('fullname'));
			var itemview = new SCMRepoItemView({model: model});
  		$("#github-repos").append(itemview.render().el);
    },
    onChange: function(){
      console.debug("RepoView catched change on collection.");
    }
	});

	return SCMRepoView;
});
