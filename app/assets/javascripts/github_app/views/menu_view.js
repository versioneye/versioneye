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
    initialize: function(){
      this.collection.bind('change', this.render, this);
      this.collection.on('all', this.render, this);
    },
    events: {
      "click li.sort-item": "onClickSortItem"
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

    onClickSortItem: function(ev){
      console.debug("Updating sort-item appareance.");
      var checker_template = _.template('<i class="icon-ok checker" style="padding-right: 5px;"></i>');
      var sort_item = $(ev.target).closest(".sort-item");
      if(sort_item.hasClass('active')){
        sort_item.removeClass('active');
        $(ev.target).find('.checker').remove();
      } else {
        sort_item.addClass('active');
        $(ev.target).prepend(checker_template({}));
      }

      return true;
    }
  });

  return GithubMenuView;
});
