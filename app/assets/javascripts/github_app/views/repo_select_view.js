define(
  ['underscore', 'backbone'],
  function(_, Backbone){
    
    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
        evaluate: /\{\{(.+?)\}\}/g
    };

    var GithubRepoSelectView = Backbone.View.extend({
      className: "span9",
      template: _.template($("#github-repo-select-template").html()),
      option_template: _.template($("#github-repo-select-option-template").html()),

      events: {
        "change .github-repo-select": "onSelectChange"
      },
      render: function(){
        var options = [];

        _.each(this.model.get('branches'), function(branch){
            options.push(this.option_template({
              value: branch,
              content: branch,
              selected: branch == "master" ? "selected" : ""
            }));
        }, this);
        
        this.$el.html(this.template({
          repo: this.model.toJSON(),
          options: options
        }));
        return this;
      },

      onSelectChange: function(ev){
        console.log("user changed branch..");
        this.model.set({branch: ev.target.value});
        console.log(this.model.get('branch'));
      }
    });

    return GithubRepoSelectView;
  });
