define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	     evaluate: /\{\{(.+?)\}\}/g
	};

	var GithubMenuView =  Backbone.View.extend({
    el: "#github-menu",
    template: _.template($("#github-menu-template").html()),
	  item_template: _.template($("#github-menu-item-template").html()),
    initialize: function(options){
      this.collection.bind('change', this.render, this);
      this.collection.on('all', this.render, this);
      this.currentRepos = options.currentRepos;
      this.allRepos = options.allRepos;
    },
    events: {
      "click li.org-item": "onOrgItem",
      "click li.sort-item": "onSortItem",
      "click li.filter-item": "onFilterItem",
      "click #github-search-btn": "onSearchItem",
      "submit #github-repo-search" : "onSearchItem"
    },
    render: function(){
      console.log("Rendering menu...");
      $(this.el).html(this.template({}));

      $(this.el).find("#github-menu-orgs").empty();
      this.collection.each(function(org){
      	$(this.el).find("#github-menu-orgs").append(
      		this.item_template({org: org.toJSON()})
      	);
      }, this)
      return this;
    },

    onOrgItem: function(ev){
      console.debug('User clicked on org-item - cleaning filtering.');
      this.removePrevSelection();
    },

    onSortItem: function(ev){
      console.debug("catched event on Sort button");
      sort_params = $(ev.target).data();

      this.currentRepos.sortByField(sort_params['field'], sort_params['order']);
      sort_params['order'] = -1 * parseInt(sort_params['order']);
      return false;
    },
    removePrevSelection: function(){
      $('.filter-item').removeClass("active");
      $('.filter-item').find('.checker').remove();
    },
    onFilterItem: function(ev){
      var checker_template = _.template('<i class="icon-ok checker" style="padding-left: 5px;"></i>');
      var filter_item = $(ev.target).parents(".filter-item");
      var filter_data = $(ev.target).data();

      this.currentRepos.currentPage = 0;
      this.currentRepos.reset();
      if(filter_item.hasClass('active')){
        this.removePrevSelection();
        this.allRepos.fetchAll();
        this.currentRepos.appendNextPage(0); //restore organization view
      } else {
        //going to add a filter
        this.removePrevSelection();
        filter_item.addClass('active');
        $(ev.target).append(checker_template({}));
        var filtered_repos = this.currentRepos.filterByField(filter_data['field'], filter_data['value']);
        this.currentRepos.addNewItems(filtered_repos);
      }
      return true;
    },
    onSearchItem: function(ev){
      ev.preventDefault();
      var search_term = $("#github-search-term").val();
      var search_matches = this.allRepos.matchByName(search_term);

      console.debug("user is searching: " + search_term);
      this.removePrevSelection();
      this.currentRepos.reset();
      this.currentRepos.addNewItems(search_matches);

      return true;
    }
  });

  return GithubMenuView;
});
