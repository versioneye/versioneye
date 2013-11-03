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
      "click .github-switch" : "onSwitchChange"
    },

    initialize: function(options){
      console.debug("Initializing switch: ")
      console.debug(options);

      this.parent = options.parent;
      this.branch = options.branch;
      this.project_file = options.project_file;
    },

    renderInfo: function(is_imported, project_info){
        not_imported_tmpl = _.template("<strong> {{= filename }} </strong>");
        imported_tmpl = _.template([
          '- <a href="{{= url}}"> <strong>{{= filename }}</strong> </a>',
          ', imported {{= moment(imported).fromNow() }}'
        ].join(' '));

        var content = "";
        var filename = this.project_file['path'];
        if(is_imported){
          content = imported_tmpl({
            branch: this.branch,
            filename: filename,
            url: project_info['project_url'],
            imported: project_info['created_at']
          });
        } else {
          content = not_imported_tmpl({filename: filename});
        }

        return content;
    },

    render: function(){
      var is_imported = false;
      var filename = this.project_file['path'];
      var project_info = {};
      var imported_files = this.model.get('imported_files');

      with_same_name = _.where(
        imported_files,
        {branch: this.branch, filename: filename}
      );
      if(!_.isEmpty(with_same_name)){
        is_imported = true;
        project_info = _.first(with_same_name);
      }
      //add view
      var switch_info = this.renderInfo(is_imported, project_info);
      this.$el.html(this.template({
        repo: this.model.toJSON(),
        branch: this.branch,
        filename: filename,
        switch_id: this.getModelSwitchId(),
        switch_info: switch_info,
        is_imported: is_imported,
        project_info: project_info
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

    onSwitchChange: function(ev){
      var this_switch = $(ev.currentTarget);
      var switch_data = this_switch.data();

      if(this_switch.attr('disabled')){
        console.log("Going to drop event of unactive switch.");
        ev.preventDefault();
        ev.stopImmediatePropagation();
        ev.stopPropagation();
        return false;
      }

      var prev_state = this_switch.attr("checked");
      this_switch.attr("checked", !prev_state);
      this_switch.attr("disabled", true);

      var notification_template = _.template($("#github-notification-template").html());
      var loading_info = notification_template({
        classes: "alert alert-info",
        content: ['<img src="/assets/loadingbar2.gif" style="height: 20px;" alt="loading" >',
          '<strong>Please wait!</strong> We are still importing data from Github.',
          'It may take up-to 4seconds. But we are almost there.'].join(' ')
      });

      if(this_switch.attr("checked")){
        this.showRepoNotification(loading_info);
        this.addProject(this_switch);
      } else {
        this.removeProject(this_switch);
      }
      return true;
    },

    switchOnActivate : function(){
      var switch_selector = "#" + this.getModelSwitchId();
      var repo_switch = $(switch_selector);

      repo_switch.bootstrapSwitch('checked', true);
      repo_switch.bootstrapSwitch('disabled', false);
    },

    switchOffActivate: function(){
      var switch_selector = "#" + this.getModelSwitchId();
      var repo_switch = $(switch_selector);

      repo_switch.attr("checked", false);
      repo_switch.attr('disabled', false);

    },

    addProject: function(el){
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

      var error_msg = ""
      if(xhr.status == 404){
        error_msg = "Server timeout. We are facing to many requests. Please Try again later.";
      } else if (xhr.status == 500){
        error_msg = "An error occurred. Please try again later and contact us on Twitter @VersionEye."
      } else {
        error_msg = "Can't import project: " + model.get('fullname')  + ".";
        error_msg += xhr.responseText;
      }
      console.debug("We encountered: " + xhr.status + " " + xhr.statusText);
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
