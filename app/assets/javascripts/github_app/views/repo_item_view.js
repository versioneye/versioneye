define(['underscore', 'backbone',
	   '/assets/github_app/views/switch_view',
 	   '/assets/github_app/views/repo_select_view',
     '/assets/github_app/views/label_view'],
  function(_, Backbone, GithubRepoSwitchView, GithubRepoSelectView,
           GithubRepoLabelView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
        evaluate: /\{\{(.+?)\}\}/g
    };
    
    var GithubRepoItemView = Backbone.View.extend({
      template: _.template($("#github-repo-info-template").html()),
      render: function(){

        var switch_view = new GithubRepoSwitchView({model: this.model});
        var label_view = new GithubRepoLabelView({model: this.model});
        var select_view = new GithubRepoSelectView({model: this.model});

        var repo_container = this.template({
          repo: this.model.toJSON()
        });
        
        this.$el.html(repo_container);
        this.$el.find(".repo-controls").append(select_view.render().el);
        this.$el.find(".repo-controls").append(switch_view.render().el);
        this.$el.find(".repo-info-content").append(label_view.render().el);
        return this;
      }
    });


  return GithubRepoItemView;
});
