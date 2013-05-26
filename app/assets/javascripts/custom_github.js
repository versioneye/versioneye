
jQuery(document).ready(function(){
  jQuery('#q').tbHinter({
    text: "json",
    styleclass: "lp_searchfield_hint"
  });

  if(jQuery("#tabs").length > 0){
    jQuery( "#tabs" ).tabs();
  }

  if(jQuery('.github_switch').length > 0){
    jQuery('.github_switch').on('switch-change', function(e, data){
      toggleGitHubProject(data.el, data.value);
    });
    console.log("Github switches are registered.");
  }

}); // end-of-ready

function fetchGitHubProjects(){
  fetchLinkArea = document.getElementById("fetchLinkArea");
  fetchLinkArea.style.display = "none";
  loadingbarArea = document.getElementById("loadingbarArea");
  loadingbarArea.style.display = "block";
  jQuery.ajax({
    url: "/user/projects/github_repositories.json"
  }).done(function (data){
    if (data){
      addGitHubProjects(data)
    }
  } );
}

function addGitHubProjects(data){
  if (data[0].projects[0] == "BAD_CREDENTIALS"){
    alert("Your GitHub token is not valid anymore. Please login again with GitHub.")
    projectListArea = document.getElementById("gitHubLogin");
    projectListArea.style.display = "block";
  } else {
    first_project = data[0].projects[0]
    if (first_project == "NO_SUPPORTED_PROJECTS_FOUND"){
      alert("Sorry. But it seems that your projects are not supported.")
    } else {
      for (i = 0; i < data[0].projects.length; i++ ){
        project = data[0].projects[i];
        var o = new Option(project, project);
        jQuery(o).html(project);
        jQuery("#github_projects").append(o);
      }
      projectListArea = document.getElementById("projectListArea");
      projectListArea.style.display = "block";
    }
  }
  loadingbarArea = document.getElementById("loadingbarArea");
  loadingbarArea.style.display = "none";
}

//TODO: finish it
function make_home_label(data){
  var repo_url = "/user/projects/" + data["project_id"];
  var label = ['<a href="' + repo_url + '">',
                '<span class = "label label-success repo-homepage ">',
                  '<i class = "icon icon-home"></i>',
                  "Project's page",
                "</span></a>"
              ].join(' ');

 return label;
}

function make_notification_bar(style, message){
 var notification_bar = [
   '<div class="alert ' + style + '">',
   '<button type="button" class="close" data-dismiss="alert">&times;</button>',
   message,
   '</div>'
 ].join(' ');
 return notification_bar;
};

function show_repo_notification(repo_id, style, message){
  jQuery("#notification-bar-" + repo_id).html(
    make_notification_bar(style, message)
  ).delay(15000).fadeOut(2000);
}

function show_repo_loader(repo_id){
  jQuery("#notification-bar-" + repo_id).html(
    '<img src="/assets/loadingbar.gif" style="width: 64px; height: 64px; margin: 0 auto; left: 45%; right: 45%; position: relative;" />'
  ).fadeIn(800);

}

function addGitHubProject(selected_el, data){
  console.debug("Going to add new Github project: ", data.githubFullname);
  var selected_item = jQuery(selected_el);
  var jqxhr = jQuery.ajax({
    type: "POST",
    url: "/user/projects",
    data: {"github_project" : data.githubFullname},
    dataType: "json"
  });

  selected_item.parents('.switch').bootstrapSwitch('setActive', false);
  show_repo_loader(data.githubId);
  // -- response handlers
  jqxhr.done(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);

    if(response.success){
      var home_label = make_home_label(response.data);
      selected_item.data('githubProjectId', response.data["project_id"]);
      jQuery("#repo-labels-" + data.githubId).append(home_label);
      show_repo_notification(data.githubId, "alert-success", "Project is added.");
    } else {
      show_repo_notification(data.githubId, "alert-warning",
                             "Fail: " + response.msg);
      selected_item.parents('.switch').bootstrapSwitch('toggleState');

    }
  });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
    selected_item.parents('.switch').bootstrapSwitch('setState', false);
    show_repo_notification(data.githubId, "alert-warning", "Backend failure: " + status);
  });

}

function removeGitHubProject(selected_el, data){
  console.debug("Going to remove GitHub project: ", data.githubFullname);
  var selected_item = jQuery(selected_el);
  if(data.githubProjectId.length > 1){
    var query_url = "/user/projects/" + data.githubProjectId + ".json";
    var jqxhr = jQuery.ajax({url: query_url, type: "DELETE"});
  } else {
   // show_repo_notification(data.githubId, "alert-warning", "Cant remove because we didnt get correct project id after importing from github.");
    return 0;
  }

  selected_item.parents('.switch').bootstrapSwitch('setActive', false);
  show_repo_loader(data.githubId);
  //-- response handlers
  jqxhr.done(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
    if(response.success){
      jQuery("#repo-labels-" + data.githubId).find(".repo-homepage").remove();
      show_repo_notification(data.githubId, "alert-success", "Project removed");
    } else {
      show_repo_notification(data.githubId, "alert-error", "Fail: " + response.msg);
      selected_item.parents('.switch').bootstrapSwitch('toggleState');
   }

  });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
    selected_item.parents('.switch').bootstrapSwitch('toggleState');
    show_repo_notification(data.githubId, "alert-warning", "Failure: " + status);
  });
}

function toggleGitHubProject(selected_el, toggle_value){
  var selected_item = jQuery(selected_el),
      data = selected_item.data();
  if(toggle_value){
    addGitHubProject(selected_el, data);
  } else {
    removeGitHubProject(selected_el, data);
  }

}
