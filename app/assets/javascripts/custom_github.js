
jQuery(document).ready(function(){
  jQuery('#q').tbHinter({
    text: "json",
    styleclass: "lp_searchfield_hint"
  });

  if(jQuery("#tabs").length > 0){
    jQuery( "#tabs" ).tabs();
  }
  
  show_github_repos(); 
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

function show_repo_notification(selector, style, message){
  var notification_template = _.template(jQuery("#github-notification-template").html());

  jQuery(selector).find(".repo-notification").html(
    notification_template({
      classes: style, 
      message: message
    })
  ).delay(10000).fadeOut(1000);
}

function show_repo_loader(selector, msg){
  var loader_template = _.template(jQuery("#github-loading-template").html());
  jQuery(selector).find(".repo-notification").html(
    loader_template({classes: "alert alert-info", message: msg})
  ).fadeIn(800);
}

function addGitHubProject(selected_el, data){
  console.debug("Going to add new Github project: ", data.githubFullname);
  var selected_item = jQuery(selected_el);
  var selected_repo_el = "#github-repo-" + data.githubId;
  var repo_label_template = _.template(jQuery("#github-repo-label-template").html());
  var url_template = _.template('<a href="{{= url}}" >{{= content }}</a>');
  
  //stop execution if switch is unactive and state is changed by code
  if (selected_item.parents('.switch').bootstrapSwitch('isActive') != true){
    console.debug("Dropping event on unactive switch;");
    return false;
  }

  show_repo_loader(selected_repo_el, "Importing data from Github..");
  var jqxhr = jQuery.ajax({
    type: "POST",
    url: "/user/projects",
    data: {"github_project" : data.githubFullname},
    dataType: "json"
  });

  selected_item.parents('.switch').bootstrapSwitch('setActive', false);
   // -- response handlers
  jqxhr.done(function(response, status, xhrReq){
    if(response.success){
      var home_label = repo_label_template({
        classes: "repo-homepage", 
        content: url_template({
                  url: "/user/projects/" + response.data["project_id"], 
                  content: repo_label_template({
                    classes: "label label-success",
                    content: '<i class= "icon-white icon-home"></i> Project home'
                  })
        })
      })
      selected_item.data('githubProjectId', response.data["project_id"]);
      jQuery(selected_repo_el).find(".repo-labels").append(home_label);
      show_repo_notification(selected_repo_el, 
                             "alert alert-success", 
                             "Project is added successfully. You can visit project's page now.");
    } else {
      show_repo_notification(selected_repo_el, 
                             "alert alert-warning",
                             "Fail: " + response.msg);
      selected_item.parents('.switch').bootstrapSwitch('toggleState');
    }
   //finally restore visibility of switch
   selected_item.parents('.switch').bootstrapSwitch('setActive', true);
 });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('setState', false);
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
    
    show_repo_notification(selected_repo_el, 
                           "alert alert-warning", 
                           "Backend failure: " + status);
  });

}

function removeGitHubProject(selected_el, data){
  console.debug("Going to remove GitHub project: ", data.githubFullname);
  var selected_item = jQuery(selected_el);
  var selected_repo_el = "#github-repo-" + data.githubId;

  if(data.githubProjectId.length > 1){
    var query_url = "/user/projects/" + data.githubProjectId + ".json";
    var jqxhr = jQuery.ajax({url: query_url, type: "DELETE"});
  } else {
    show_repo_notification(selected_repo_el, 
                           "alert alert-warning", 
                           "Cant remove because we didnt get correct project id after importing from github.");
    return 0; //stop executing
  }

  selected_item.parents('.switch').bootstrapSwitch('setActive', false);
  show_repo_loader(selected_repo_el, "");
  //-- response handlers
  jqxhr.done(function(response, status, xhrReq){
    if(response.success){
      jQuery(selected_repo_el).find(".repo-homepage").remove();
      show_repo_notification(selected_repo_el, 
                             "alert alert-success", 
                             "Project is now removed.");
      //clean project id on switch
      selected_item.data('githubProjectId', "");
    } else {
      show_repo_notification(selected_repo_el, 
                             "alert-error", 
                             "Fail: " + response.msg);
      selected_item.parents('.switch').bootstrapSwitch('toggleState');
   }
    //finally restore visibility of switch 
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
  });

  jqxhr.fail(function(response, status, xhrReq){
    selected_item.parents('.switch').bootstrapSwitch('toggleState');
    selected_item.parents('.switch').bootstrapSwitch('setActive', true);
    show_repo_notification(selected_repo_el, 
                           "alert alert-warning", 
                           "Failure: Cant remove project - backend failure.");
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

// -- functions to render views 

function render_github_loading(selector){
  var loading_template = _.template(jQuery("#github-loading-template").html());
  jQuery(selector).html(loading_template({
    classes: "alert alert-info",
    message: "Please wait - we are importing github repostiories."
  }));
}

function make_github_repo_labels(repo){
  var repo_label_template = _.template(jQuery("#github-repo-label-template").html());
  var url_template = _.template('<a href="{{= url}}" >{{= content }}</a>');
  var labels = "";
  
  labels += repo_label_template({
    classes: "repo-type label label-warning", 
    content: _.template("<strong>{{= type}}</strong>", 
                        {type: (repo.private) ? "private": "public"})
  });
 
  labels += repo_label_template({
    classes: "repo-language label label-info",
    content: "" + repo.language
  });
  var timeago = moment(repo.updated_at).fromNow();
  labels += repo_label_template({
    classes: "repo-updated label", 
    content: "<strong>updated:&nbsp;</strong>" + timeago
  });
  if (repo.project_url){
    labels += repo_label_template({
      classes: "repo-homepage",
      content: url_template({
        url: repo.project_url, 
        content: repo_label_template({
          classes: "label label-info", 
          content: '<i class= "icon-white icon-home"></i>&nbsp;Project page ' 
        })
      })
    });
  }
  return labels
};

function render_github_repo_row(selector, repo){
  var table_row_template = _.template(jQuery("#github-table-row-template").html());
  var repo_info_template = _.template(jQuery("#github-repo-info-template").html());
  var repo_switch_template = _.template(jQuery("#github-repo-switch-template").html());
  
  var info_content = repo_info_template({
      repo: repo,
      labels: make_github_repo_labels(repo),
      github_switch: repo_switch_template({repo: repo})
  });
  var row_content = table_row_template({content: info_content});

  jQuery(selector).append(row_content);
}

function render_github_repo_table(selector, repos){
  var table_template = _.template(jQuery("#github-table-template").html());
  var table_selector = "#github-repos-table > tbody";
  jQuery(selector).html(table_template({}));
  //render rows
  _.each(repos, function(repo, index, coll){
    render_github_repo_row(table_selector, repo);
  });

  //register events
  jQuery(".switch").bootstrapSwitch();
  jQuery('.github_switch').on('switch-change', function(e, data){
    toggleGitHubProject(data.el, data.value);
  });
  console.log("Github switches are registered.");
}

function render_github_pagination(selector, paging){
  var container_template = _.template(jQuery("#github-pagination-template").html());
  var item_template = _.template(jQuery("#github-pagination-item-template").html());
  var paging_items = [];

  for(i = 1; i < paging.total_pages; i++){
    var item_classes = "paging-item";
    item_classes += (i == paging.current_page) ? " active" : ""

    paging_items.push(item_template({
      page:  i, 
      classes: item_classes,
      paging: paging
    }));
  }

  var pagination = container_template({
    classes: "pagination-centered",
    items: paging_items.join('')
  });
  jQuery(selector).append(pagination);

  //register pagination events
  jQuery("#github_pagination").find(".paging-item").on("click", function(ev){
    var paging_data = jQuery(ev.target).data();
    console.debug("Going to load page nr: " + paging_data.page);
    jQuery(ev.target).toggleClass("active");
    show_github_repos(paging_data.page, paging_data.perPage);
    return false;
  });
}

function render_github_fail(selector, response){
  var notification_template = _.template(jQuery("#github-notification-template").html());
  jQuery(selector).html(notification_template({
    classes: "alert alert-warning",
    message: "<strong> Error! </strong> Cant read github repos: your account is not connected or Github is taking nap."
  }));
}

// -- main function that iniatialise view renderings
function show_github_repos(page, per_page){
  console.debug("Going to render githup repos ...");
  _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
      evaluate: /\{\{(.+?)\}\}/g
  };

  var content_selector = "#github-repos";
  var page = page || 1;
  var per_page = per_page || 10;
  var request_url = "/user/projects/github_repos?page=" + page + "&per_page=" + per_page;
  render_github_loading(content_selector);
  var jqxhr = jQuery.ajax({
    url: request_url,
    dataType: "json",
    cache: false //required
  });

  //-- response handlers
  jqxhr.done(function(data, status, jqxhr){
    console.debug("Got github repos" + status);
    if(data.success){
      render_github_repo_table(content_selector, data.repos);
      render_github_pagination(content_selector, data.paging)
    } else {
      console.debug("Controller failed");
      render_github_fail(content_selector, data);
    }
  });
  jqxhr.fail(function(data, status, jqxhr){
    console.debug("Failed to read github repos" + status);
    render_github_fail(content_selector, data);
  });

}
