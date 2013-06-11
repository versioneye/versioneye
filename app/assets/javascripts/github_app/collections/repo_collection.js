define(['underscore', 'backbone', 'paginator'],
  function(_, Backbone, Paginator){

	var GithubRepoModel = Backbone.Model.extend({});
  var GithubRepoCollection = Backbone.Paginator.requestPager.extend({
    model: GithubRepoModel,
    paginator_core: {
      type: 'GET',
      dataType: 'json',
      url: '/user/github_repos'
    },
    paginator_ui: {
      firstPage: 1,
      currentPage: 1,
      perPage: 5
    },
    server_api: {
      per_page: function(){return this.perPage;},
      page: function(){return this.currentPage;}
    },
    parse: function(response){
      if(response.success){
        this.totalPages = response.paging.total_pages;
        this.totalRecords = response.paging.total_entries;
        this.currentPage = response.paging.current_page;
        if(response.repos.length){
          console.log("Got " + response.repos.length + " repos.");
          return response.repos;
        } else {
          console.log("Got no repos;");
          $("#github-repos").html("You have no repositories on Github or Github is not accessible.");
        }

      } else {
        return []
      }
    }
  });

  return GithubRepoCollection;
});
