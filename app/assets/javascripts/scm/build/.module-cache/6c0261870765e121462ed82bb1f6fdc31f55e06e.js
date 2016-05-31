/** @jsx React.DOM */

var repoFilesInterval = 0;
var imported_files = [];
var fileImportTimeout;

var RepoFiles = React.createClass({displayName: "RepoFiles",
  loadRepoFilesFromServer: function() {
    $.ajax({
      url: this.props.url,
      dataType: 'json',
      success: function(data) {
        this.setState({data: data.repo, task_status: data.task_status});
        if (data.task_status == "done"){
          clearInterval( repoFilesInterval );
        }
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  getInitialState: function() {
    return {data: [], task_status: ''};
  },
  componentDidMount: function() {
    this.loadRepoFilesFromServer();
    repoFilesInterval = setInterval(this.loadRepoFilesFromServer, this.props.pollInterval);
  },
  render: function() {

    repo_fullname = this.props.repo_fullname;
    scm = this.props.scm;

    var branches = [];
    if (this.state.data.branches){
      branches = this.state.data.branches;
    }

    var project_files = [];
    if (this.state.data.project_files){
      project_files = this.state.data.project_files;
    }

    if (this.state.data.imported_files){
      imported_files = this.state.data.imported_files;
    }

    var scm_branches = branches.map(function (branch) {
      return (
        React.createElement("div", {className: "repo-controls span8"}, 
          React.createElement("div", {className: "table table-striped"}, 
            React.createElement(RepoBranch, {data: branch, project_files: project_files, repo_fullname: repo_fullname, scm: scm})
          )
        )
      );
    });

    return (
      React.createElement("div", {id: "branches"}, 

        React.createElement(TaskStatusMessage, {data: this.state.task_status, repo_fullname: repo_fullname, scm: scm, show_reimport_link: "true"}), 

        scm_branches

      )
    );
  }
});

var RepoBranch = React.createClass({displayName: "RepoBranch",
  render: function() {
    repo_fullname = this.props.repo_fullname;
    scm = this.props.scm;
    branch = this.props.data;
    project_files = this.props.project_files

    var branch_files = null;
    if (project_files && project_files != "" && project_files[branch]){
      branch_files = project_files[branch].map(function (project_file) {
        return (
          React.createElement(BranchFile, {data: project_file, branch: branch, repo_fullname: repo_fullname, scm: scm})
        );
      });
    }
    if (branch_files == null || branch_files == ""){
      branch_files = "We couldn't find any supported project files in this branch."
    }
    return (
      React.createElement("div", null, 
        React.createElement("div", {className: "scm_branch_head"}, 
          React.createElement("p", null, 
            React.createElement("i", {className: "fa fa-code-fork"}), " ", branch
          )
        ), 
        React.createElement("div", {className: "scm_branch_files_cell"}, 
          branch_files
        )
      )
    );
  }
});


var BranchFile = React.createClass({displayName: "BranchFile",
  onChange: function( e ) {
    scm = this.props.scm
    checked = e.target.checked
    if (checked == true ){
      this.setState({import_status: 'running', checked: false});
      id = e.target.id
      thisComponent = this
      fileImportTimeout = setInterval(function(){
        url = "/user/projects/"+ scm +"/" + id.replace(/\//g,':') + "/import";
        $.ajax({
          url: url,
          dataType: 'json',
          success: function(data, status) {
            if (data.status == 'done'){
              imported_files.push(data);
              thisComponent.setState({import_status: data.status, checked: true});
              clearInterval( fileImportTimeout )
            }
          }.bind(this),
          error: function(xhr, status, err) {
            var err_msg = xhr.responseText
            if (err_msg == null || err_msg == ""){
              err_msg = "We are not able to import the selected file. Please contact the VersionEye team."
            }
            alert("ERROR: " + err_msg);
            thisComponent.setState({import_status: '', checked: false});
            console.error(err_msg);
            clearInterval( fileImportTimeout )
          }.bind(this)
        });
      }, 1000) // end setInterval() - 1 Second
    } else {
      this.setState({import_status: 'off', checked: false});
      id = e.target.id
      url = "/user/projects/"+ scm +"/" + id.replace(/\//g,':') + "/remove";
      $.ajax({
        url: url,
        dataType: 'json',
        success: function(data) {
          removeFromImportedFiles( this.state.project_id )
          this.setState({import_status: '', checked: false, project_url: '', project_id: ''});
        }.bind(this),
        error: function(xhr, status, err) {
          console.error(err.toString());
        }.bind(this)
      });
    }
  },
  getInitialState: function() {
    return {checked: false, import_status: '', project_id: '', project_url: ''};
  },
  render: function() {

    repo_fullname = this.props.repo_fullname
    branch = this.props.branch;
    path   = this.props.data.path
    uid  = repo_fullname + "::" + branch + "::" + path
    uids = repo_fullname + "::" + branch + "::" + path + "_status"

    this.state.checked = false;
    for (var i in imported_files) {
      ifile = imported_files[i];
      if (ifile.branch == branch && ifile.filename == path) {
        this.state.checked = true;
        this.state.project_id = ifile.project_id;
        this.state.project_url = ifile.project_url;
        break;
      }
    }

    return (
      React.createElement("div", {className: "display: block;"}, 
        React.createElement("div", {className: "scm_switch_cell"}, 
          React.createElement("div", {className: "onoffswitch"}, 
              React.createElement("input", {type: "checkbox", 
                     name: "onoffswitch", 
                     checked: this.state.checked, 
                     onChange: this.onChange, 
                     className: "onoffswitch-checkbox", 
                     id: uid}), 
              React.createElement("label", {className: "onoffswitch-label", htmlFor: uid}, 
                  React.createElement("span", {className: "onoffswitch-inner"}), 
                  React.createElement("span", {className: "onoffswitch-switch"})
              )
          )
        ), 
        React.createElement("div", {className: "scm_switch_text_cell"}, 
          React.createElement(ProjectFile, {import_status: this.state.import_status, project_id: this.state.project_id, project_url: this.state.project_url, id: uids, name: this.props.data.path})
        ), 
        React.createElement("br", null), 
        React.createElement("br", null), React.createElement("br", null)
      )
    );

  }
});


var ProjectFile = React.createClass({displayName: "ProjectFile",
  getInitialState: function() {
    return {import_status: '', project_id: '', project_url: ''};
  },
  render: function() {
    this.state.import_status = this.props.import_status;
    this.state.project_url = this.props.project_url;
    this.state.project_id = this.props.project_id;
    if (this.state.import_status == 'running'){
      return (
        React.createElement("table", {className: "scm_table"}, 
          React.createElement("tr", null, 
            React.createElement("td", {className: "scm_td"}, React.createElement("img", {src: "/assets/progress-small.gif", alt: "work in progress"})), 
            React.createElement("td", {className: "scm_td"}, this.props.name)
          )
        )
      );
    } else if (this.state.project_url) {
      return (
        React.createElement("a", {href: this.state.project_url}, " ", this.props.name, " ")
      );
    } else {
      return (
        React.createElement("span", null, this.props.name)
      );
    }
  }
});


function removeFromImportedFiles( project_id ){
  for (var i in imported_files) {
    ifile = imported_files[i];
    if (ifile.project_id == project_id) {
      delete imported_files[i]
      break;
    }
  }
}
