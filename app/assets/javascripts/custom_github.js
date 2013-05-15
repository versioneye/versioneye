
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
