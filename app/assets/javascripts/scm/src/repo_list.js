/** @jsx React.DOM */

var repoListInterval = 0;
var store = [];

var RepoList = React.createClass({
  loadReposFromServer: function() {
    $.ajax({
      url: this.props.url,
      dataType: 'json',
      success: function(data) {
        something_changed = data.repos.length != store.length || data.task_status != this.state.task_status
        if (something_changed){
          store = data.repos;
          this.setState(
            {data: data.repos,
             list_size: data.repos.length,
             task_status: data.task_status});
        }
        if (data.task_status == "done"){
          clearInterval( repoListInterval );
        }
      }.bind(this),
      error: function(xhr, status, err) {
        console.error(this.props.url, status, err.toString());
      }.bind(this)
    });
  },
  getInitialState: function() {
    return {data: [], text: '', list_size: 0, task_status: ''};
  },
  componentWillMount: function() {
    this.loadReposFromServer();
    repoListInterval = setInterval(this.loadReposFromServer, this.props.pollInterval);
  },
  onChange: function( e ) {
    filtered = [];
    data = store; // this.state.data
    count = 0;
    for (var key in data) {
       if (data.hasOwnProperty(key)) {
          if (data[key]['fullname'].toLowerCase().indexOf( e.target.value.toLowerCase() ) != -1) {
            filtered[key] = data[key];
            count += 1;
          }
       }
    }
    this.setState({data: filtered, list_size: count, text: e.target.value})
  },
  render: function() {
    var scm = this.props.scm
    var clear_link = "/user/" + this.props.scm + "/clear";
    var scm_repos = this.state.data.map(function (repo) {
      return (
        <ScmRepo data={repo} scm={scm} />
      );
    });
    return (
      <div >
        <div>
          <input type="text" id="filter_input" class="form-control" value={this.state.text} onChange={this.onChange} />
        </div>
        <div className="scm_meta" >
          {this.state.list_size} Repositories - <a href={clear_link}>Reimport all Repositories</a>
        </div>
        <TaskStatusMessage data={this.state.task_status} />
        {scm_repos}
      </div>
    );
  }
});

var ScmRepo = React.createClass({
  render: function() {
    var url = "/user/projects/" + this.props.scm + "/" + this.props.data.fullname + "/show"
    return (
      <div className="scm_repo" >
        <a href={url} >{this.props.data.fullname}</a>
      </div>
    );
  }
});


var TaskStatusMessage = React.createClass({
  render: function() {
    if (this.props.data == 'running'){
      return (
        <div><img src="/assets/progress.gif" alt="work in progress" /> Import is running ... be patient and drink a soda.</div>
      );
    } else if (this.props.show_reimport_link == "true")  {
      url = "/user/projects/" + this.props.scm + "/" + this.props.repo_fullname + "/reimport";
      return (
        <p><a href={url} >Update meta-data about this repository</a><br/><br/></p>
      );
    } else {
      return (
        <div></div>
      )
    }
  }
});
