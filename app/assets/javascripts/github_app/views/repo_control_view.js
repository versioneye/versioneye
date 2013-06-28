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
      template: _.template($("#github-repo-control-template").html()),
      render: function(){
        var project_branches = this.model.get('branches');

        this.$el.html(this.template({
          branches: project_branches,
          imported_branches: this.model.get('imported_branches')
        }));

        // -- add subitems
        _.each(project_branches, function(branch){
          var item_view = new GithubRepoControlItemView({
            model: this.model,
            branch: branch
          });

          this.$el.append(item_view.render().$el);
        }, this);

        return this;
      }
    });

    return GithubRepoControlView;
  });
