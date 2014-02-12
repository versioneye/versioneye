define([
        'underscore', 'backbone',
        '/assets/scm_app/views/repo_control_item_view'],
  function(_, Backbone, SCMRepoControlItemView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var SCMRepoControlView = Backbone.View.extend({
      tagName: "table",
      className: "github-repo-control table table-striped row-fluid",

      render: function(){
        var project_branches = this.model.get('branches') || [];

        if( _.size(project_branches) > 0 ){
          this.render_controls(project_branches);
        } else {
          this.render_empty_controls();
        }

        return this;
      },

      render_controls: function(project_branches){
        var project_files = this.model.get('project_files') || [];

        _.each(project_branches, function(branch){
          var branch_files = project_files[branch] || [];
          var item_view = new SCMRepoControlItemView({
            model: this.model,
            branch: branch,
            project_files: branch_files
          });
          this.$el.append(item_view.render().$el);

        }, this);
      },

      render_empty_controls: function(){
        this.$el.html("No supported files on branches;");
      }
    });

    return SCMRepoControlView;
  });
