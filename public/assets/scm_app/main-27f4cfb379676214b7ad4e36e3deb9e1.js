define(["underscore","backbone","moment","/assets/scm_app/views/loading_view","/assets/scm_app/views/menu_view","/assets/scm_app/views/repo_view","/assets/scm_app/views/pagination_view","/assets/scm_app/collections/all_repo_collection","/assets/scm_app/collections/repo_collection","/assets/scm_app/collections/menu_collection"],function(e,t,n,i,r,a,o,s,l,u){var c=t.Router.extend({initialize:function(e){this.app=e.app},routes:{user:"showRepos","org/:org_id":"showRepos","*path":"showDefaultRepos"},showDefaultRepos:function(){var e=new i;e.render(),this.app.allRepos.poller.start()},showRepos:function(t){var n=this.app.allRepos,i=this.app.currentRepos;(e.isNaN(t)||e.isUndefined(t))&&(t=get_default_org(n)),i.org_id!==t&&(console.log("Org id changed - cleaning up & resetting view."),this.app.currentRepos.org_id=t,this.app.currentRepos.reset()),console.log("going to show repos for: "+t),n.length&&!e.isEmpty(n.first().toJSON())?(console.debug("All_repos still have some repos: "+n.length),i.appendNextPage(0)):n.poller.start()}}),h=function(n){return this.options=n||{},this.showNotification=function(t,n){var i=e.template($("#github-notification-template").html());$(".flash-container").html(i({classes:t,content:n})).fadeIn(400).delay(6e3).fadeOut(800)},this.get_default_org=function(e){var t=e.first();return t.get("user_login")},this.allRepos=new s([],{app:this,urls:this.options.repo_urls}),this.currentRepos=new l([],{allRepos:this.allRepos}),this.repoView=new a({app:this,collection:this.currentRepos}),this.paginationView=new o({app:this,collection:t.Collection.extend({}),currentRepos:this.currentRepos}),this.menuItems=new u([],{urls:this.options.repo_urls}),this.menuView=new r({app:this,collection:this.menuItems,currentRepos:this.currentRepos,allRepos:this.allRepos,repoView:this.repoView}),this.initViews=function(t){this.menuItems.fetch({}),(e.isNaN(this.currentRepos.org_id)||e.isUndefined(this.currentRepos.org_id))&&(this.currentRepos.org_id=this.get_default_org(t)),console.debug("Initializing view with org-id: "+this.currentRepos.org_id),this.currentRepos.reset(),this.currentRepos.perPage=10,this.currentRepos.appendNextPage(0),this.paginationView.render()},this.start=function(){console.log("Running SCM app with options: "),console.debug(this.options);{var n=this;new c({app:this})}t.history.start(),this.allRepos.poller.on("success",function(t){console.info("another successful fetch!");var i=(e.template($("#github-notification-template").html()),$("#github-loader-notification"));i.empty(),(e.isUndefined(t)||e.isEmpty(t))&&i.html("Still reading data from SCM ."),!e.isUndefined(t)&&!e.isNull(t)&&!e.isEmpty(t)&&t.length>0&&(n.currentRepos.length<10&&(console.debug("Going to re=render page;"),n.initViews(t)),"done"===t.at(0).get("task_status")?(i.html(["Got ",t.length,"repositories."].join(" ")),n.initViews(t)):i.html(['<i class = "icon-spinner icon-spin"></i>'," Please be patient. The import of your repositories is in progress. We imported already ",t.length,"repositories."].join(" ")))}),this.allRepos.poller.on("error",function(){console.error("oops! something went wrong. Backend issue during polling.")})},this};return h});