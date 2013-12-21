define(['underscore', 'backbone'],
  function(_, Backbone){

	var SCMRepoModel = Backbone.Model.extend({
    idAttribute: "_id"
  });

  var SCMRepoCollection = Backbone.Collection.extend({
    model: SCMRepoModel,
    sortKey: 'pushed_at',
    sortOrder: -1,
    initialize:  function(model, options){
      this.allRepos = options.allRepos;
    },

    comparator: function(repo){
      var string_to_code = function(string_val){
        var bytes = _.map(string_val.split(""), function(c){return c.charCodeAt();});
        var code= 0;
        for(i= 0, n=bytes.length; i< n; i++){
          code += bytes[i] * Math.pow(8, (n-i));
        }
        return code;
      };

      var sort_val = repo.get(this.sortKey);
      if(this.sortKey == "updated_at" || this.sortKey == 'pushed_at'){
        sort_val = new Date(sort_val).valueOf();
      }

      if(_.isString(sort_val)){
        sort_val = string_to_code(sort_val);
        console.debug(sort_val);
      }

      return (this.sortOrder > 0) ? sort_val: -sort_val;
    },
    sortByField: function(field_name, order){
      console.debug('Sorting repos by: ' + field_name + ' order: ' + order );
      this.sortOrder = parseInt(order);
      this.sortKey = field_name;
      this.sort();
    },
    filterByField: function(field_name, value){
      console.debug("Filtering org: " + this.org_id + ' by field ' + field_name + ' with value ' + value);
      var filtered_repos = this.onlyOrgRepos().filter(function(repo){return repo.get(field_name) == value}, this);

      return filtered_repos;
    },
    onlyOrgRepos: function(){
      console.log("Filtering orgs by: " + this.org_id);
      var org_repos = this.allRepos.filter(function(repo){return repo.get("owner_login") == this.org_id}, this);
      return org_repos;
    },
    addNewItems: function(new_repos){
      console.debug(new_repos.length);

      var since = (this.currentPage * this.perPage);
      console.log("Going to add next items since: " + since);
      this.totalPages = Math.ceil(new_repos.length/ this.perPage);

      var next_slice = new_repos.slice(since, since + this.perPage);
      this.add(next_slice, {update: true});
    },
    appendNextPage: function(to_page){
      if(!_.isNaN(to_page) && !_.isUndefined(to_page)){
        this.currentPage = to_page; //move to page
      }
      if(_.isNaN(this.currentPage) || _.isUndefined(this.currentPage)){
        console.debug("RepoCollection has no currentPage defined.");
        this.currentPage = 0;
      }

      if(_.isNaN(this.perPage) || _.isUndefined(this.perPage)){
        this.perPage = 5;
      }
      var org_repos = this.onlyOrgRepos();
      this.addNewItems(org_repos);

      return this;
    }
  });

  return SCMRepoCollection;
});
