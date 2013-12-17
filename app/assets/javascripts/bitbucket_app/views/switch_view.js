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
      this.parent = options.parent;
      this.branch = options.branch;
      this.project_file = options.project_file;
    },

    renderInfo: function(project_info){
        not_imported_tmpl = _.template("<strong> {{= filename }} </strong>");
        imported_tmpl = _.template([
          '<a href="{{= url}}"> <strong>{{= filename }}</strong> </a>',
          ', imported {{= moment(imported).fromNow() }}'
        ].join(' '));

        var content = "";
        var filename = this.project_file['path'];

        if(!_.isNull(project_info) && !_.isUndefined(project_info)){
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

    getImportedFileInfo: function(filename){
      var imported_files = this.model.get('imported_files');
      var project_info = null;
      var is_imported = false;

      with_same_name = _.where(
        imported_files,
        {branch: this.branch, filename: filename}
      );

      if(!_.isEmpty(with_same_name)){
        is_imported = true;
        project_info = _.first(with_same_name);
      }

      return {is_imported: is_imported, info: project_info};
    },
    render: function(){
      var filename = this.project_file['path'];
      var imported_project = this.getImportedFileInfo(filename);

      //add view
      var switch_info = this.renderInfo(imported_project.info);
      this.$el.html(this.template({
        repo: this.model.toJSON(),
        branch: this.branch,
        filename: filename,
        switch_id: this.getModelSwitchId(),
        switch_info: switch_info,
        is_imported: imported_project.is_imported,
        project_info: imported_project.is_imported ? imported_project.info : {project_id: null}
      }));
      return this;
    },

    getModelSwitchId: function(){
      var prefix =  "github-repo-switch-" + this.model.get('github_id') + "-" + this.project_file['uuid'];
      return _.uniqueId(prefix);
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
      this.disableSwitch(this_switch);

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
    disableSwitch: function(this_switch){
      this_switch.attr("disabled", true);
      this_switch.parents('.onoffswitch').addClass('disabled');
    },
    enableSwitch: function(this_switch){
      this_switch.attr("disabled", false);
      this_switch.parents('.onoffswitch').removeClass('disabled');
    },
    switchOnActivate : function(){
      var repo_switch = this.$el.find('input');
      repo_switch.attr('checked', true);
      this.enableSwitch(repo_switch);
    },

    switchOffActivate: function(){
      var repo_switch = this.$el.find('input');
      repo_switch.attr("checked", false);
      this.enableSwitch(repo_switch);
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
      var command_result = model.get('command_result');
      var msg = ['<strong> Success! </strong>',
                 'Project file ' , command_result['filename'],
                 ' on branch ', command_result['branch'],
                 ' of Github project ', model.get('fullname'),
                 ' is now successfully imported.',
                 'You can now checkout project\'s page.'
                 ].join(' ');

      var this_switch = this.$el.find('input');
      this_switch.data('githubProjectId', command_result['project_id']);
      this.updateRepoTitle(command_result);
      this.updateRepoProjectInfo(model);
      this.switchOnActivate();
      this.hideRepoNotification();
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
      this.hideRepoNotification();
      var this_switch = this.$el.find('input');
      this.switchOffActivate(this_switch);

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
      var command_result = model.get('command_result');
      var msg = [
        '<strong>Success!</strong>',
        'The Project\'s file ', command_result['filename'],
        ' from the Github repository ', model.get('fullname') ,
        ' is now successfully removed.'
      ].join(' ');

      this.updateRepoTitle();
      this.updateRepoProjectInfo(model);
      this.switchOffActivate();
      showNotification("alert alert-success", msg);
      this.hideRepoNotification();
      return true;
    },
    onRemoveFailure: function(model, xhr, options){
      var msg = "Fail: Can not remove project";
      this.switchOnActivate();
      showNotification("alert alert-warning", msg);
      this.hideRepoNotification();
      return false;
    },

    updateRepoTitle: function(project_info){
      var new_title = this.renderInfo(project_info);
      this.$el.find(".item-title").html(new_title);
    },

    updateRepoProjectInfo:  function(model){
      var info_template = _.template($('#github-repo-project-info-template').html());
      var imported_files = this.model.get('imported_files') || [];
      var imported_urls = _.map(imported_files, function(item){
        var url_name = item['branch'] + '/' + item['filename'];
        return ['<a href="', item['project_url'], '" > ', url_name, ' </a>'].join('');
      });
      var branch_info = info_template({
        branches: this.model.get('branches'),
        imported_urls: imported_urls
      });

      this.$el.parents('.repo-container').find(".repo-project-info").html(branch_info);
    },

    showRepoNotification: function(msg){
      notifier = $(this.el).parents('.repo-container').find(".repo-notification");
      notifier.removeClass('hide');
      notifier.html(msg);
    },

    hideRepoNotification: function(){
      this.$el.parents('.repo-container').find(".repo-notification").html("").addClass('hide');
    }
  });

  return GithubRepoSwitchView;
});
