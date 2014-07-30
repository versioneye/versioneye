/** @jsx React.DOM */

var repoFilesInterval = 0;
var imported_files = [];

var RepoFiles = React.createClass({displayName: 'RepoFiles',
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
        React.DOM.div({className: "repo-controls span8"}, 
          React.DOM.div({className: "table table-striped"}, 
            RepoBranch({data: branch, project_files: project_files, repo_fullname: repo_fullname, scm: scm})
          )
        )
      );
    });

    return (
      React.DOM.div(null, 
        TaskStatusMessage({data: this.state.task_status}), 

        scm_branches

      )
    );
  }
});

var RepoBranch = React.createClass({displayName: 'RepoBranch',
  render: function() {
    repo_fullname = this.props.repo_fullname;
    scm = this.props.scm;
    branch = this.props.data;
    project_files = this.props.project_files

    var branch_files = null;
    if (project_files && project_files != ""){
      branch_files = project_files[branch].map(function (project_file) {
        return (
          BranchFile({data: project_file, branch: branch, repo_fullname: repo_fullname, scm: scm})
        );
      });
    }
    if (branch_files == null || branch_files == ""){
      branch_files = "We couldn't find any supported project files in this branch."
    }
    return (
      React.DOM.div(null, 
        React.DOM.div({className: "scm_branch_head"}, 
          React.DOM.p(null, 
            React.DOM.i({className: "icon-code-fork"}), " ", branch
          )
        ), 
        React.DOM.div({className: "scm_branch_files_cell"}, 
          branch_files
        )
      )
    );
  }
});

var BranchFile = React.createClass({displayName: 'BranchFile',
  onChange: function( e ) {
    scm = this.props.scm

    if (e.target.checked == true ){
      this.setState({import_status: 'running', checked: false});
      url = "/user/projects/"+ scm +"/" + e.target.id.replace(/\//g,':') + "/import";
      $.ajax({
        url: url,
        dataType: 'json',
        success: function(data) {
          imported_files.push(data);
          this.setState({import_status: '', checked: true});
        }.bind(this),
        error: function(xhr, status, err) {
          alert("An error occured. We are not able to import the selected file. Please contact the VersionEye team.")
          this.setState({import_status: '', checked: false});
          console.error(err.toString());
        }.bind(this)
      });
    } else {
      this.setState({import_status: 'runnin', checked: false});
      url = "/user/projects/"+ scm +"/" + this.state.project_id + "/remove";
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
      React.DOM.div({className: "row-fluid"}, 
        React.DOM.div({className: "scm_switch_cell"}, 
          React.DOM.div({className: "onoffswitch"}, 
              React.DOM.input({type: "checkbox", 
                     name: "onoffswitch", 
                     checked: this.state.checked, 
                     onChange: this.onChange, 
                     className: "onoffswitch-checkbox", 
                     id: uid}), 
              React.DOM.label({className: "onoffswitch-label", htmlFor: uid}, 
                  React.DOM.span({className: "onoffswitch-inner"}), 
                  React.DOM.span({className: "onoffswitch-switch"})
              )
          )
        ), 
        React.DOM.div({className: "scm_switch_text_cell"}, 
          ProjectFile({import_status: this.state.import_status, project_id: this.state.project_id, project_url: this.state.project_url, id: uids, name: this.props.data.path})
        )
      )
    );

  }
});


var ProjectFile = React.createClass({displayName: 'ProjectFile',
  getInitialState: function() {
    return {import_status: '', project_id: '', project_url: ''};
  },
  render: function() {
    this.state.import_status = this.props.import_status;
    this.state.project_url = this.props.project_url;
    this.state.project_id = this.props.project_id;
    if (this.state.import_status == 'running'){
      return (
        React.DOM.table({className: "scm_table"}, 
          React.DOM.tr(null, 
            React.DOM.td({className: "scm_td"}, React.DOM.img({src: "/assets/progress-small.gif", alt: "work in progress"})), 
            React.DOM.td({className: "scm_td"}, this.props.name)
          )
        )
      );
    } else if (this.state.project_url) {
      return (
        React.DOM.a({href: this.state.project_url}, " ", this.props.name, " ")
      );
    } else {
      return (
        React.DOM.span(null, this.props.name)
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
