define([
  'underscore', 'backbone', 'moment',
	'/assets/github_app/views/switch_view'],
  function(_, Backbone, moment, GithubRepoSwitchView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var GithubRepoControlItemView = Backbone.View.extend({
      tagName: "li",
      className: "repo-control-item",
      template: _.template($("#github-repo-control-item-template").html()),
      initialize: function(options){
        this.branch = options.branch;
      },
      renderTitle: function(){
        not_imported_tmpl = _.template("<strong> {{= branch }} </strong>");
        imported_tmpl = _.template([
          '<strong>{{= branch }}</strong>', 
          '- <a href="{{= url}}"> projects page </a>',
          ', imported {{= moment(imported).fromNow() }}'
        ].join(' '));

        var content = "";
        var imported_branches =  this.model.get('imported_branches');
       
        if(_.has(imported_branches, this.branch)){
          var imported_branch = imported_branches[this.branch];
          content = imported_tmpl({
            branch: this.branch,
            url: imported_branch.project_url,
            imported: imported_branch.created_at
          });
        } else {
          content = not_imported_tmpl({branch: this.branch});
        }

        return content
      },
      render: function(){
        this.$el.html(this.template({branch: this.branch}));

        var switch_view = new GithubRepoSwitchView({
          model: this.model, 
          parent: this,
          branch: this.branch
        });

        this.$el.find('.item-title').html(this.renderTitle());        
        this.$el.find('.item-switch').html(switch_view.render().$el);
        return this;
      }
    });
    return GithubRepoControlItemView;
  });
