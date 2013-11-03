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
      info_template: _.template($('#github-repo-control-info-template').html()),
      events: {
        "click .controls-toggle": "toggleBranchView"
      },
      render: function(){
        var control_view = new GithubRepoControlView({model: this.model});
        var label_view = new GithubRepoLabelView({model: this.model});
        var repo_container = this.template({repo: this.model.toJSON()});

        this.$el.html(repo_container);

        var branch_info = this.info_template({
          branches: this.model.get('branches'),
          imported_files: this.model.get('imported_files')
        });

        this.$el.find(".repo-controls-info").html(branch_info);
        this.$el.find(".repo-controls").append(control_view.render().el);
        this.$el.find(".repo-labels").append(label_view.render().el);

        //this.$el.find(".github-switch").bootstrapSwitch();
        return this;
      },
      toggleBranchView: function(ev){
        var repo_sliders = this.$el.find(".repo-slider");
        var current_slider = this.$el.find(".repo-slider.current");
        var next_slider_id = "#" + current_slider.data('next');
        var next_slider = this.$el.find(next_slider_id);

        next_slider.removeClass("hide");
        repo_sliders.toggleClass("current");
        current_slider.addClass("hide");
        return false;
      }
    });

  return GithubRepoItemView;
});
