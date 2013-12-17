define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

  var GithubPaginationView = Backbone.View.extend({
    events: {
      "click .btn-pagination-next": "loadMore"
    },
    template: _.template($("#github-pagination-template").html()),
    initialize: function (options) {
      this.currentRepos = options.currentRepos;
      this.currentRepos.on('all', this.render, this);
      this.currentRepos.on('reset', this.resetView, this);
      $('#github-pagination').html(this.$el);
    },
    render: function(){
      console.debug("Rendering pagination view.");
      this.$el.html(this.template({
        paging: {
          currentPage: this.currentRepos.currentPage,
          totalPages:  this.currentRepos.totalPages,
          perPage: this.currentRepos.perPage
        }
      }));
      //$('#github-pagination').html(this.$el)
    },
    resetView: function(){
      this.currentRepos.currentPage = 0;
      this.render();
    },
    loadMore: function(e){
      this.currentRepos.currentPage += 1;
      console.debug("Showing more results.");
      console.debug(this.currentRepos.currentPage);
      this.currentRepos.appendNextPage();
      return false;
    }
  });

  return GithubPaginationView;
});
