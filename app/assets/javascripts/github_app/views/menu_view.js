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
    }
  });

  return GithubMenuView;
});