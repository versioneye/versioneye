require.config({
    paths: {
        'underscore': '/assets/libs/underscore-min',
        'backbone': '/assets/libs/backbone-min',
        'moment': '/assets/libs/moment.min'
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

      var bitbucket_app = new SCMApp({
        name: "SCMApp for Bitbucket",
        repo_urls: {
          root: '/user/bitbucket_repos',
          clear: '/user/bitbucket/clear'
        }
      });

      bitbucket_app.start();
  });

}); // end-of-ready


