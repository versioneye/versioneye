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
    className: "span3",
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
      console.debug(switch_data);
      is_switch_active = switch_data.el.parents('.switch').bootstrapSwitch("isActive");
      
      if(!is_switch_active){
        console.log("Going to drop event of unactive switch.");
        ev.preventDefault();
        ev.stopImmediatePropagation();
        ev.stopPropagation();
        return false;
      }

      switch_data.el.parents(".switch").bootstrapSwitch('setActive', false);

      var notification_template = _.template($("#github-notification-template").html());
      var loading_info = notification_template({
        classes: "alert alert-info",
        content: ['<img src="/assets/loadingbar2.gif" style = "height: 20px;">',
          '<strong>Please wait!</strong> We are still importing data from Github.',
          'It may take up-to 4seconds. But we are almost there.'].join(' ')
      });

      if(switch_data.value){
        switch_data.el.parents(".repo-container").find(".repo-notification").html(loading_info);
        this.addProject(switch_data.el, switch_data.value);
      } else {
        this.removeProject(switch_data.el), switch_data.value;
      } 
      return true;
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

      var repo_switch = $(switch_selector).parents(".github-switch");
      
      repo_switch.bootstrapSwitch('setState', true);
      repo_switch.bootstrapSwitch('setActive', true);
      $(switch_selector).parents(".repo-container").find(".repo-notification").html("");
      showNotification("alert alert-success", msg);
      return true;
    },

    onAddFailure: function(model, xhr, options){
      var error_msg = "Failure: Cant import project: " + model.get('fullname');
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
      var repo_switch = $(switch_selector).parents(".github-switch");
      
      showNotification("alert alert-success", error_msg);
      console.debug(error_msg);
      $(switch_selector).parents(".repo-container").find(".repo-notification").html("");
      repo_switch.bootstrapSwitch("setState", false);
      repo_switch.bootstrapSwitch('setActive', true);
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
      return false;
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
      var repo_switch = $(switch_selector).parents(".github-switch");
      
      repo_switch.bootstrapSwitch('setState', false);
      repo_switch.bootstrapSwitch('setActive', true);
      showNotification("alert alert-success", msg);

      return true;
   },
   onRemoveFailure: function(model, xhr, options){
      var msg = "Fail: Cant remove project";
      var switch_selector = "#github-repo-switch-" + model.get('github_id');
      var repo_switch = $(switch_selector).parents(".github-switch");
      
      repo_switch.bootstrapSwitch('setState', true);
      repo_switch.bootstrapSwitch('setActive', true);
      showNotification("alert alert-warning", msg);

      return false;
    }
  });

  return GithubRepoSwitchView;
});
