define(['underscore', 'backbone',
	   '/assets/scm_app/views/repo_control_view',
     '/assets/scm_app/views/label_view'],
  function(_, Backbone, SCMRepoControlView, SCMRepoLabelView){

    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
         evaluate: /\{\{(.+?)\}\}/g
    };

    var SCMRepoItemView = Backbone.View.extend({
      className: "spanX",

      template: _.template($("#github-repo-info-template").html()),
      info_template: _.template($('#github-repo-project-info-template').html()),
      events: {
        "click .controls > .toggle-next": "toggleBranchView",
        "click .controls > .update-repo": "updateRepository"
      },
      render: function(){
        var control_view = new SCMRepoControlView({model: this.model});
        var label_view = new SCMRepoLabelView({model: this.model});
        var repo_container = this.template({repo: this.model.toJSON()});

        this.$el.html(repo_container);
        var imported_files = this.model.get('imported_files') || [];
        var imported_urls = _.map(imported_files, function(item){
          var url_name = item['branch'] + '/' + item['filename'];
          return ['<a href="', item['project_url'], '" > ', url_name, ' </a>'].join('');
        });
        var branch_info = this.info_template({
          branches: this.model.get('branches'),
          imported_urls: imported_urls
        });

        this.$el.find(".repo-project-info").html(branch_info);
        this.$el.find(".repo-controls").append(control_view.render().el);
        this.$el.find(".repo-labels").append(label_view.render().el);

        return this;
      },
      toggleBranchView: function(ev){
        var repo_sliders = this.$el.find(".repo-slider");
        var current_slider = this.$el.find(".repo-slider.current");
        var next_slider_id = "#" + current_slider.data('next');
        var next_slider = this.$el.find(next_slider_id);

        next_slider.removeClass("hide");
        repo_sliders.toggleClass("current");
        current_slider.addClass("hide");
        return false;
      },

      updateRepository: function(ev){
        var repo_info = this.$el.children(".repo-container").data();
        var that = this;
        var btn = this.$el.find(".controls .update-repo.btn");
        this.disableUpdateButton(btn);
        this.showUpdateLoader(btn);
        this.model.save({
          command: "update",
          command_data: repo_info
        },
        {
          beforeSend: function(xhr){
            xhr.setRequestHeader(
              'X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')
            );
          },
          success: function(model, xhr, options){
            that.onUpdateSuccess(model, btn)
          },
          error: function(model, xhr, options){
            console.debug(xhr);
            that.onUpdateFailure(model, btn, xhr);
          }
        });
      },


      onUpdateSuccess: function(model, btn){
        console.debug("Update was successful.");
        this.removeUpdateLoader(btn);
        this.enableUpdateButton(btn);
        this.render();
      },
      onUpdateFailure: function(model, btn){
        console.debug("Update failed;")
        this.removeUpdateLoader(btn);
        this.enableUpdateButton(btn);
      },
      showUpdateLoader: function(btn){
        btn.find('i.icon-refresh').addClass('icon-spin');
        btn.find('span.btn-title').text('Reading the newest information');
      },
      removeUpdateLoader: function(btn){
        btn.find("i.icon-refresh").removeClass("icon-spin");
        btn.find("span.btn-title").text("Update the repository")
      },
      disableUpdateButton: function(btn){
        btn.addClass('disabled');
        btn.attr('disabled', true);
      },
      enableUpdateButton: function(btn){
        btn.removeClass('disabled');
        btn.attr('disabled', false);
      }

    });

  return SCMRepoItemView;
});//end of module
