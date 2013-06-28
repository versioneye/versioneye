define(['underscore', 'backbone',
	   '/assets/github_app/views/repo_control_view',
     '/assets/github_app/views/label_view'],
  function(_, Backbone, GithubRepoControlView, GithubRepoLabelView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var GithubRepoItemView = Backbone.View.extend({
      template: _.template($("#github-repo-info-template").html()),
      render: function(){
        var control_view = new GithubRepoControlView({model: this.model});
        var label_view = new GithubRepoLabelView({model: this.model});
        
        var repo_container = this.template({repo: this.model.toJSON()});

        this.$el.html(repo_container);
        this.$el.find(".repo-controls").append(control_view.render().el);
        this.$el.find(".repo-labels").append(label_view.render().el);

        this.$el.find(".github-switch").bootstrapSwitch();
        return this;
      }
    });

  return GithubRepoItemView;
});
