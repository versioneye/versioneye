define([
        'underscore', 'backbone',
        '/assets/github_app/views/repo_control_item_view'],
  function(_, Backbone, GithubRepoControlItemView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var GithubRepoControlView = Backbone.View.extend({
      tagName: "ul",
      className: "github-repo-control nav nav-stacked",
      render: function(){
        var project_branches = this.model.get('branches') || [];
        var project_files = this.model.get('project_files') || [];
        _.each(project_branches, function(branch){

          var branch_files = project_files[branch] || [];
          console.debug("Branch files: ")
          console.debug(branch);
          console.debug(branch_files);
          var item_view = new GithubRepoControlItemView({
            model: this.model,
            branch: branch,
            project_files: branch_files
          });
          this.$el.append(item_view.render().$el);

        }, this);

        return this;
      }
    });

    return GithubRepoControlView;
  });
