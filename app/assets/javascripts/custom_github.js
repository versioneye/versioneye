
function fetchGitHubProjects(){
  fetchLinkArea = document.getElementById("fetchLinkArea");
  fetchLinkArea.style.display = "none";
  loadingbarArea = document.getElementById("loadingbarArea");
  loadingbarArea.style.display = "block";
  jQuery.ajax({
    url: "/user/projects/github_projects.json"
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
  ).show(3000).fadeOut(800);
}

function show_repo_loader(repo_id){
  jQuery("#notification-bar-" + repo_id).html(
    '<img src="/assets/loadingbar.gif" style="width: 64px; height: 64px; margin: 0 auto;" />'
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
  show_repo_loader(data.githubId);
  // -- response handlers
  jqxhr.done(function(response, status, xhrReq){
    var home_label = make_home_label(response);
    selected_item.data('githubProjectId', response["project_id"]);
    jQuery("#repo-labels-" + data.githubId).append(home_label);
    show_repo_notification(data.githubId, "alert-success", "Project is added.");
  });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.bootstrapSwitch('setState', false);
    show_repo_notification(data.githubId, "alert-warning", "Failure: " + status);
  });

}

function removeGitHubProject(selected_el, data){
  console.debug("Going to remove GitHub project: ", data.githubFullname);
  var selected_item = jQuery(selected_el);
  var query_url = "/user/projects/" + data.githubProjectId + ".json";
  var jqxhr = jQuery.ajax({url: query_url, type: "DELETE"});

  show_repo_loader(data.githubId);
  //-- response handlers
  jqxhr.done(function(response, status, xhrReq){
    jQuery("#repo-labels-" + data.githubId).find(".repo-homepage").remove();
    show_repo_notification(data.githubId, "alert-success", "Project removed");
  });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.bootstrapSwitch('toggleState');
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
