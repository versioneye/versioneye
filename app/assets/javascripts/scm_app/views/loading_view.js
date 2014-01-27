define(['underscore', 'backbone'],
  function(_, Backbone){

	_.templateSettings = {
		interpolate: /\{\{\=(.+?)\}\}/g,
	    evaluate: /\{\{(.+?)\}\}/g
	};

	var SCMLoadingView = Backbone.View.extend({
		el: "#github-repos",
		template: _.template($("#github-loading-template").html()),
		render: function(){
			$(this.el).html(this.template({
				classes: "alert alert-info",
				message: "Please wait, we are importing data from SCM."
			}));
		}
	});

	return SCMLoadingView;
});
