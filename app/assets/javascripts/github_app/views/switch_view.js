define(['underscore', 'backbone'],
  function(_, Backbone){

  _.templateSettings = {
    interpolate: /\{\{\=(.+?)\}\}/g,
    evaluate: /\{\{(.+?)\}\}/g
  };

  var showNotification = function(classes, message){
    var flash_template = _.template($("#github-notification-template").html());
    $(".flash-container").html(flash_template({
      classes: classes,
      content: message
    })).fadeIn(400).delay(6000).fadeOut(800);
  }

  var GithubRepoSwitchView = Backbone.View.extend({
    template: _.template($("#github-repo-switch-template").html()),
    events: {
      "switch-change .switch" : "onSwitchChange"
    },

    initialize: function(options){
      this.parent = options.parent;
      this.branch = options.branch;
    },

    render: function(){
      this.$el.html(this.template({
        repo: this.model.toJSON(),
        branch: this.branch,
        switch_id: this.getModelSwitchId()
      }));
      return this;
    },

    getModelSwitchId: function(){
      var id =  "github-repo-switch-" + this.model.get('github_id');
      if(this.branch){
        id += "-" + this.branch;
      }

      return id;
    },

    onSwitchChange: function(ev, switch_data){
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
        content: ['<img src="/assets/loadingbar2.gif" style="height: 20px;" alt="loading" >',
          '<strong>Please wait!</strong> We are still importing data from Github.',
          'It may take up-to 4seconds. But we are almost there.'].join(' ')
      });

      if(switch_data.value){
        this.showRepoNotification(loading_info);
        this.addProject(switch_data.el, switch_data.value);
      } else {
        this.removeProject(switch_data.el), switch_data.value;
      }
      return true;
    },

    switchOnActivate : function(){
      var switch_selector = "#" + this.getModelSwitchId();
      var repo_switch = $(switch_selector).parents(".github-switch");

      repo_switch.bootstrapSwitch('setState', true);
      repo_switch.bootstrapSwitch('setActive', true);
    },

    switchOffActivate: function(){
      var switch_selector = "#" + this.getModelSwitchId();
      var repo_switch = $(switch_selector).parents(".github-switch");

      repo_switch.bootstrapSwitch("setState", false);
      repo_switch.bootstrapSwitch('setActive', true);

    },

    addProject: function(el, data){
      console.log("Adding new project");
      var current_switch = this;
      this.model.save(
        {
          command: "import",
          command_data: el.data()
        },
        {
          beforeSend: function(xhr) {
            xhr.setRequestHeader('X-CSRF-Token',
                                 $('meta[name="csrf-token"]').attr('content'));
          },
          success: function(model, xhr, options){
            var that_switch = current_switch;
            that_switch.onAddSuccess(model)
          },
          error: function(model, xhr, options){
            console.debug(xhr);
            var that_switch = current_switch;
            that_switch.onAddFailure(model, xhr);
          }
        });
    },

    onAddSuccess: function(model){
      var msg = ['<strong> Success! </strong>',
                 'Github project ', model.get('fullname'),
                 ' is now successfully imported.',
                 'You can now checkout project\'s page to see state of dependencies.'
                 ].join(' ');

      var command_data = model.get('command_data');
      $(this.el).find('.input').data('githubProjectId', command_data['githubProjectId']);
      this.updateRepoTitle();
      this.switchOnActivate();
      this.showRepoNotification("");
      showNotification("alert alert-success", msg);
      return true;
    },

    onAddFailure: function(model, xhr){
      var error_msg = "Failure: Can not import project: " + model.get('fullname')  + ".";
      error_msg += xhr.responseText;

      console.debug(error_msg);
      showNotification("alert alert-error", error_msg);
      this.showRepoNotification("");
      this.switchOffActivate();

      $(this.el).find(".repo-notification").html("");
      return false;
    },

    removeProject: function(el, data){
      console.log("Removing selected project.");

      var current_switch = this;
      this.model.save(
        {
          command: "remove",
          command_data: el.data()
        },
        {
          beforeSend: function(xhr) {
            xhr.setRequestHeader('X-CSRF-Token',
                                 $('meta[name="csrf-token"]').attr('content'));
          },
          success: function(model, xhr, options){
            var that_switch = current_switch;
            that_switch.onRemoveSuccess(model);
          },
          error: function(model, xhr, options){
            var that_switch = current_switch;
            that_switch.onRemoveFailure(model);
          }
        }
      );
      return false;
    },

    onRemoveSuccess: function(model){
      var selector = "#github-repo-" + model.get("github_id");
      var msg = [
        '<strong>Success!</strong>',
        'Github project ', model.get('fullname'),
        ' is now successfully removed from your projects.'
      ].join(' ');

      this.updateRepoTitle();
      this.switchOffActivate();
      showNotification("alert alert-success", msg);

      return true;
    },
    onRemoveFailure: function(model, xhr, options){
      var msg = "Fail: Can not remove project";

      this.switchOnActivate();
      showNotification("alert alert-warning", msg);

      return false;
    },

    updateRepoTitle: function(){
      new_title = this.parent.renderTitle();
      $(this.el).parents(".repo-control-item").find('.item-title').html(new_title);
    },

    showRepoNotification: function(msg){
      $(this.el).parents('.repo-container').find(".repo-notification").html(msg);
    }
  });

  return GithubRepoSwitchView;
});
