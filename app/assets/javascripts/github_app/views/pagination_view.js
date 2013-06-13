define(['underscore', 'backbone', 'paginator'],
  function(_, Backbone, Paginator){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

  var GithubPaginationView = Backbone.View.extend({
    events: {
      "click .btn-pagination-next": "loadMore"
    },
    template: _.template($("#github-pagination-template").html()),
    initialize: function () {
      this.collection.on('sync', this.render, this);
      $('#github-pagination').html(this.$el);
    },
    render: function(){
      $(this.el).html(this.template({
        paging: {
          currentPage: this.collection.currentPage,
          totalPages:  this.collection.totalPages
        }
      }));
    },
    loadMore: function(e){
      console.debug("Showing more results.");
      this.collection.requestNextPage();
      return false;
    }
  });

  return GithubPaginationView;
});
