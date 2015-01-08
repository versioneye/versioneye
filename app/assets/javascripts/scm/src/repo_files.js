/** @jsx React.DOM */

var repoFilesInterval = 0;
var imported_files = [];
var fileImportTimeout;

var RepoFiles = React.createClass({
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
        <div className="repo-controls span8">
          <div className="table table-striped">
            <RepoBranch data={branch} project_files={project_files} repo_fullname={repo_fullname} scm={scm} />
          </div>
        </div>
      );
    });

    return (
      <div id="branches" >

        <TaskStatusMessage data={this.state.task_status} repo_fullname={repo_fullname} scm={scm} show_reimport_link="true" />

        {scm_branches}

      </div>
    );
  }
});

var RepoBranch = React.createClass({
  render: function() {
    repo_fullname = this.props.repo_fullname;
    scm = this.props.scm;
    branch = this.props.data;
    project_files = this.props.project_files

    var branch_files = null;
    if (project_files && project_files != ""){
      branch_files = project_files[branch].map(function (project_file) {
        return (
          <BranchFile data={project_file} branch={branch} repo_fullname={repo_fullname} scm={scm} />
        );
      });
    }
    if (branch_files == null || branch_files == ""){
      branch_files = "We couldn't find any supported project files in this branch."
    }
    return (
      <div>
        <div className="scm_branch_head" >
          <p>
            <i className="icon-code-fork"></i> {branch}
          </p>
        </div>
        <div className="scm_branch_files_cell" >
          {branch_files}
        </div>
      </div>
    );
  }
});


var BranchFile = React.createClass({
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
      <div className="row-fluid">
        <div className="scm_switch_cell" >
          <div className="onoffswitch">
              <input type="checkbox"
                     name="onoffswitch"
                     checked={this.state.checked}
                     onChange={this.onChange}
                     className="onoffswitch-checkbox"
                     id={uid} />
              <label className="onoffswitch-label" htmlFor={uid}>
                  <span className="onoffswitch-inner"></span>
                  <span className="onoffswitch-switch"></span>
              </label>
          </div>
        </div>
        <div className="scm_switch_text_cell">
          <ProjectFile import_status={this.state.import_status} project_id={this.state.project_id} project_url={this.state.project_url} id={uids} name={this.props.data.path}  />
        </div>
      </div >
    );

  }
});


var ProjectFile = React.createClass({
  getInitialState: function() {
    return {import_status: '', project_id: '', project_url: ''};
  },
  render: function() {
    this.state.import_status = this.props.import_status;
    this.state.project_url = this.props.project_url;
    this.state.project_id = this.props.project_id;
    if (this.state.import_status == 'running'){
      return (
        <table className="scm_table">
          <tr>
            <td className="scm_td" ><img src="/assets/progress-small.gif" alt="work in progress" /></td>
            <td className="scm_td" >{this.props.name}</td>
          </tr>
        </table>
      );
    } else if (this.state.project_url) {
      return (
        <a href={this.state.project_url} > {this.props.name} </a>
      );
    } else {
      return (
        <span>{this.props.name}</span>
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
