require.config({
    paths: {
        'underscore': '/assets/libs/underscore-min',
        'backbone': '/assets/libs/backbone-min',
        'moment': '/assets/libs/moment.min',
        'bootstrap_switch': '/assets/libs/bootstrap_switch',
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

 require(["underscore", "backbone","/assets/scm_app/main"],
    function(_, Backbone, SCMApp) {

      var github_app = new SCMApp({
        name: "SCMApp for Github",
        repo_urls: {
          root: '/user/github_repos',
          clear: '/user/github/clear'
        }
      });

      github_app.start();
  });

}); // end-of-ready


