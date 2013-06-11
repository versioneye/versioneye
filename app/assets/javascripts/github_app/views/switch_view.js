define(['underscore', 'backbone'],
  function(_, Backbone){

  _.templateSettings = {
    interpolate: /\{\{\=(.+?)\}\}/g,
    evaluate: /\{\{(.+?)\}\}/g
  };
      
  var showNotification = function(classes, message){
    var flash_template = _.template(jQuery("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(3000).fadeOut(800);
  }

 
  var addRepoLinkLabel = function(selector, model){
    var url_label_template = _.template(jQuery("#github-repo-urllabel-template").html());
    $(selector).find('.repo-labels').append(url_label_template({
      classes: "label label-info repo-homepage",
      url: model.get("project_url"),
      content: '<i class="icon-home"></i> Project\'s page'
    }));
  }

  var removeRepoLinkLabel = function(selector){
    $(selector).find('.repo-homepage').remove();
  }


  var GithubRepoSwitchView = Backbone.View.extend({
  		template: _.template($("#github-repo-switch-template").html()),
  		events: {
  			"switch-change .switch" : "onSwitchChange"
  		},

  		initialize: function(options){
  			this.parent = options.parent;
  		},

  		render: function(){
  			this.$el.html(this.template({repo: this.model.toJSON()}));
  			return this;
  		},

  		onSwitchChange: function(ev, switch_data){
        is_switch_active = switch_data.el.parent().bootstrapSwitch("isActive");

        switch_data.el.parents(".github-switch").bootstrapSwitch('setActive', false);

        if(is_switch_active && switch_data.value){
          this.addProject(switch_data.el, switch_data.value);
        } else if (is_switch_active && !switch_data.value) {
          this.removeProject(switch_data.el), switch_data.value;
        } else {
          console.log("Going to drop event of unactive switch.");
          switch_data.el.parents(".github-switch").bootstrapSwitch('setActive', true);
        }
  			return false;
  		},

  		addProject: function(el, data){
  			console.log("Adding new project");
  	    this.model.save(
          {command: "import"}, 
          {
            beforeSend: function(xhr) {
              xhr.setRequestHeader('X-CSRF-Token',
                                   $('meta[name="csrf-token"]').attr('content'));
            },
            success: this.onAddSuccess,
            error: this.onAddFailure
          });
      },

      onAddSuccess: function(model, xhr, options){
        var selector = "#github-repo-" + model.get("github_id");
        var switch_selector = "#github-repo-switch-" + model.get('github_id');
        var msg = ['<strong> Success! </strong>',
                   'Github project ', model.get('fullname'),
                   ' is now successfully imported.', 
                   'You can now checkout project\'s page to see state of dependencies.'
                   ].join(' ');
        addRepoLinkLabel(selector, model);
        $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
        showNotification("alert alert-success", msg);
        return true;
      },

      onAddFailure: function(model, xhr, options){
        console.log("Failure: Cant import project: " + model.get('fullname'));
        var switch_selector = "#github-repo-switch-" + model.get('github_id');
        $(switch_selector).parents(".github-switch").bootstrapSwitch("setState", false);
        $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
        return false;
      },

  		removeProject: function(el, data){
  			console.log("Removing selected project.");
        this.model.save(
          {command: "remove"},
          {
            beforeSend: function(xhr) {
              xhr.setRequestHeader('X-CSRF-Token', 
                                   $('meta[name="csrf-token"]').attr('content'));
            },
            success: this.onRemoveSuccess,
            error: this.onRemoveFailure
          }
        );
  		},

     onRemoveSuccess: function(model, xhr, options){
        var selector = "#github-repo-" + model.get("github_id");
        var msg = [
          '<strong>Success!</strong>',
          'Github project ', model.get('fullname'),
          ' is now successfully removed from your projects.'
        ].join(' ');
        
        console.log("Going to remove label from: "+ selector);
        removeRepoLinkLabel(selector);
        var switch_selector = "#github-repo-switch-" + model.get('github_id');
        $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
        showNotification("alert alert-succes", msg);

        return true;
     },
     onRemoveFailure: function(model, xhr, options){
        var msg = "Fail: Cant remove project";
        var switch_selector = "#github-repo-switch-" + model.get('github_id');

        $(switch_selector).parents(".github-switch").bootstrapSwitch('setState', true);
        $(switch_selector).parents(".github-switch").bootstrapSwitch('setActive', true);
        showNotification("alert alert-warning", msg);

        return false;
      }
  });

  return GithubRepoSwitchView;
});
