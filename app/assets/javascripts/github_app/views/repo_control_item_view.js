define([
  'underscore', 'backbone', 'moment',
	'/assets/github_app/views/switch_view'],
  function(_, Backbone, moment, GithubRepoSwitchView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var GithubRepoControlItemView = Backbone.View.extend({
      tagName: "tr",
      className: "repo-control-item",
      template: _.template($("#github-repo-control-item-template").html()),

      initialize: function(options){
        this.branch = options.branch || "<no defined>";
        this.project_files = options.project_files || [];
      },
      render: function(){
        this.$el.html(this.template({branch: this.branch}));
        var target_el = this.$el.find('.item-body');
        var that = this;
        _.each(this.project_files, function(project_file){
          var switch_view = new GithubRepoSwitchView({
            model: that.model,
            parent: that,
            branch: that.branch,
            project_file: project_file
          }, this);

          target_el.append(switch_view.render().$el);
        });
        return this;
      }
    });
    return GithubRepoControlItemView;
  });
