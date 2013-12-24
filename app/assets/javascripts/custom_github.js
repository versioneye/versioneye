require.config({
    paths: {
        'underscore': '/assets/libs/underscore-min',
        'backbone': '/assets/libs/backbone-min',
        'moment': '/assets/libs/moment.min',
        'bootstrap_switch': '/assets/libs/bootstrap_switch'
    },
    shim: {
        'underscore': {
            exports: '_'
        },
        'backbone': {
            deps: ['underscore'],
            exports: 'Backbone'
        }
    }
});

jQuery(document).ready(function(){
  jQuery('#q').tbHinter({
    text: "json"
  });

  if(jQuery("#tabs").length > 0){
    jQuery( "#tabs" ).tabs();
  }

  require(["underscore", "backbone","/assets/github_app/main"],
    function(_, Backbone, githubApp) {
      console.log("Loading required modules...");

      githubApp.init();
  });

}); // end-of-ready


