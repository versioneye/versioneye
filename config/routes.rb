Versioneye::Application.routes.draw do

  root :to => "products#index"

  get  'docker/remote_images', :to => 'docker#remote_images'

  namespace :auth do
    get  '/github/callback',   :to => 'github#callback'
    get  '/github/new',        :to => 'github#new'
    post '/github/create',     :to => 'github#create'

    get  '/bitbucket/signin',   :to => 'bitbucket#signin'
    get  '/bitbucket/connect',  :to => 'bitbucket#connect'
    get  '/bitbucket/callback', :to => 'bitbucket#callback'
    get  '/bitbucket/new',      :to => 'bitbucket#new'
    post '/bitbucket/create',   :to => 'bitbucket#create'
  end

  # get   '/cloudcontrol/resources', :to => 'cloudcontrol#resources'

  # DEBUG
  # -----
  # author: @rmetzler
  # description: this is a debugging route to help designing the suggestion-email
  #
  # REMOVE THE NEXT LINE FROM production / master branch / default branch
  #
  # get   '/emailhelper', :to => 'emailhelper#show'

  resources :sessions, :only => [:new, :create, :destroy]
  get    '/signin',                :to => 'sessions#new'
  get    '/signout',               :to => 'sessions#destroy'

  post '/users/mobile',            :to => 'users#create_mobile'

  get '/users/autocomplete', :to => 'users#autocomplete'
  resources :users, :key => :username do
    member do
      get 'favoritepackages'
      get 'comments'
      get 'users_location'
    end
  end

  get   '/created'                             , :to => 'users#created'
  get   '/signup'                              , :to => 'users#new'
  get   '/users/activate/:source/:verification', :to => 'users#activate'
  get   '/iforgotmypassword'                   , :to => 'users#iforgotmypassword'
  post  '/resetpassword'                       , :to => 'users#resetpassword'
  get   '/updatepassword/:verification'        , :to => 'users#show_update_password'
  post  '/updatepassword'                      , :to => 'users#update_password'

  resource :lottery do
    get  '/verify',    :to => "lotteries#show_verification"
    get  '/signin',    :to => "lotteries#show_signin"
    get  '/libraries', :to => "lotteries#libraries"
    post '/follow',    :to => "lotteries#follow"
    get  '/thankyou',  :to => "lotteries#thankyou"
  end

  get   '/package/latest',                      :to => 'latest_releases#index'
  get   '/package/latest/stats/:timespan',      :to => 'latest_releases#stats'
  get   '/package/latest/timeline30',           :to => 'latest_releases#lang_timeline30'
  get   '/package/latest/:lang',                :to => 'latest_releases#show'

  get   '/package/novel',                      :to => 'novel_releases#index'
  get   '/package/novel/stats/:timespan',      :to => 'novel_releases#stats'
  get   '/package/novel/timeline30',           :to => 'novel_releases#lang_timeline30'
  get   '/package/novel/:lang',                :to => 'novel_releases#show'

  namespace :settings do

    get  'profile'             , :to => 'profile#index'
    post 'update_profile'      , :to => 'profile#update'

    get  'links'               , :to => 'links#index'
    post 'update_links'        , :to => 'links#update'

    get  'emails'              , :to => 'emails#index'
    post 'add_email'           , :to => 'emails#add_email'
    post 'delete_email'        , :to => 'emails#delete_email'
    post 'make_email_default'  , :to => 'emails#make_email_default'

    get  'emailsettings'       , :to => 'emailsettings#index'
    post 'emailsettings'       , :to => 'emailsettings#update'

    get  'globalsettings'      , :to => 'globalsettings#index'
    post 'globalsettings'      , :to => 'globalsettings#update'

    get  'githubsettings'      , :to => 'globalsettings#index_github'
    post 'githubsettings'      , :to => 'globalsettings#update_github'

    get  'cocoapods'           , :to => 'globalsettings#index_cocoapods'
    post 'cocoapods'           , :to => 'globalsettings#update_cocoapods'

    get  'nexussettings'       , :to => 'globalsettings#index_nexus'
    post 'nexussettings'       , :to => 'globalsettings#update_nexus'

    get  'notifications'       , :to => 'user_notification_settings#index'
    post 'update_notifications', :to => 'user_notification_settings#update'

    get  'password'            , :to => 'password#index'
    post 'update_password'     , :to => 'password#update'

    get  'privacy'             , :to => 'privacy#index'
    post 'update_privacy'      , :to => 'privacy#update'

    get  'connect'             , :to => 'connect#index'
    get  'disconnect'          , :to => 'connect#disconnect'

    get  'api'                 , :to => 'api#index'
    post 'api'                 , :to => 'api#update'

    get  'delete'              , :to => 'delete#index'
    post 'destroy'             , :to => 'delete#destroy'

    get  'plans'               , :to => 'plan#index'
    post 'update_plan'         , :to => 'plan#update'

    get  'creditcard'          , :to => 'creditcard#index'
    post 'update_creditcard'   , :to => 'creditcard#update'

    get  'billing'             , :to => 'billing#index'
    post 'update_billing'      , :to => 'billing#update'
    get  'update_billing'      , :to => 'billing#index'

    get  'payments'            , :to => 'payments#index'
    get  'receipt/:invoice_id' , :to => 'payments#receipt', :as => 'receipt'

  end

  get   '/vc/:id', :to => 'versioncomments#show'
  resources :versioncomments
  resources :versioncommentreplies

  get '/user/packages/popular_in_my_projects'   , :to => "user/packages#popular_in_my_projects"
  get '/user/packages/i_follow'                 , :to => "user/packages#i_follow"

  get '/user/projects/github_repositories'      , :to => 'user/github_repos#init'
  get '/user/projects/bitbucket_repositories'   , :to => 'user/bitbucket_repos#init'

  get  '/user/projects/:id/recursive_dependencies', :to => 'dependency_wheel#project_recursive_dependencies'
  post '/user/projects/:id/recursive_dependencies', :to => 'dependency_wheel#project_recursive_dependencies'

  namespace :user do

    resources :projects do
      member do
        get  'badge'
        get  'visual'
        post 'save_period'
        post 'save_email'
        post 'save_visibility'
        post 'transitive_dependencies'
        post 'save_notify_after_api_update'
        post 'reparse'
        post 'followall'
        post 'update_name'
        post 'add_collaborator'
        post 'mute_dependency'
        post 'demute_dependency'
      end
    end

    resources :collaborations do
      post 'approve'
      post 'delete'
      post 'invite'
      post 'save_period'
      post 'save_email'
    end

    resources :github_repos
    get '/github/fetch_all' , :to => 'github_repos#fetch_all'
    get '/github/clear'     , :to => 'github_repos#clear'
    get '/github/menu'      , :to => 'github_repos#show_menu_items'

    resources :bitbucket_repos
    get '/bitbucket/fetch_all'  , :to => 'bitbucket_repos#fetch_all'
    get '/bitbucket/clear'      , :to => 'bitbucket_repos#clear'
    get '/bitbucket/menu'       , :to => 'bitbucket_repos#show_menu_items'

    resource :testimonials
  end

  post  '/services/choose_plan'               ,  :to => 'services#choose_plan'
  post  '/services'                           ,  :to => 'services#create'
  get   '/services/:id'                       ,  :to => 'services#show', :as => 'service'
  get   '/services/:id/recursive_dependencies',  :to => 'dependency_wheel#project_recursive_dependencies'
  post  '/services/:id/recursive_dependencies',  :to => 'dependency_wheel#project_recursive_dependencies'

  get   '/pricing',            :to => 'services#pricing'
  get   '/news',               :to => 'news#news'
  get   '/mynews',             :to => 'news#news'
  get   '/hotnews',            :to => 'news#news'

  namespace :admin do

    post '/language/upload',  :to => 'language#upload_json'
    get  '/language/download', :to => 'language#download_json'
    resources :language

    resources :submitted_urls do
      post '/approve',            :to => 'submitted_urls#approve'
      post '/decline',            :to => 'submitted_urls#decline'
    end

    resource :testimonials do
      put '/approve', :to => 'testimonials#approve'
      put '/decline', :to => 'testimonials#decline'
    end

    resources :error_messages
    resources :crawles

    get   '/crawles',             :to => 'crawles#index'
    get   '/group/:group',        :to => 'crawles#group', :as => 'group'
  end

  post  '/submitted_urls',      :to => 'submitted_urls#create'

  post  '/feedback',            :to => 'feedback#feedback'

  get   '/statistics',            :to => 'statistics#index'
  get   '/statistics/proglangs',  :to => 'statistics#proglangs'
  get   '/statistics/langtrends', :to => 'statistics#langtrends'

  get   '/about',               :to => 'page#about'
  get   '/impressum',           :to => 'page#impressum'
  get   '/faq',                 :to => 'page#faq'
  get   '/imprint',             :to => 'page#imprint'
  get   '/nutzungsbedingungen', :to => 'page#nutzungsbedingungen'
  get   '/terms',               :to => 'page#terms'
  get   '/datenschutz',         :to => 'page#datenschutz'
  get   '/dataprivacy',         :to => 'page#dataprivacy'
  get   '/datenerhebung',       :to => 'page#datenerhebung'
  get   '/datacollection',      :to => 'page#datacollection'
  get   '/disclaimer',          :to => 'page#disclaimer'
  get   '/logos',               :to => 'page#logos'

  get   'sitemap__01.xml',        :to => 'page#sitemap_1'
  get   'sitemap__02.xml',        :to => 'page#sitemap_2'
  get   'sitemap__03.xml',        :to => 'page#sitemap_3'
  get   'sitemap__04.xml',        :to => 'page#sitemap_4'
  get   'sitemap__05.xml',        :to => 'page#sitemap_5'
  get   'sitemap__06.xml',        :to => 'page#sitemap_6'
  get   'sitemap__07.xml',        :to => 'page#sitemap_7'

  get   '/search', :to => 'products#search'

  get   '/package/autocomplete'   , :to => 'products#autocomplete_product_name'
  get   '/package/name'           , :to => 'products#autocomplete_product_name'
  post  '/package/follow'         , :to => 'products#follow'
  post  '/package/unfollow'       , :to => 'products#unfollow'
  post  '/package/image_path'     , :to => 'dependency_wheel#image_path'
  post  '/package/upload_image'   , :to => 'dependency_wheel#upload_image'

  # Rewriting old legacy paths
  get   '/package/:key'                       , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/ }
  get   '/product/:key'                       , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/ }
  get   '/package/:key/badge'                 , :to => 'page#legacy_badge_route', :constraints => { :key => /[^\/]+/ }
  get   '/package/:key/version/:version'      , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/package/:key/version/:version/badge', :to => 'page#legacy_badge_route', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/product/:key/version/:version'      , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/package/:key/:version'              , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/product/:key/:version'              , :to => 'page#legacy_route',       :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  get   '/package_visual/:key'                 , :to => 'page#show_visual_old', :constraints => { :key => /[^\/]+/ }
  get   '/package_visual/:key/version/:version', :to => 'page#show_visual_old', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/package_visual/:key/:version'        , :to => 'page#show_visual_old', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  constraints( LanguageConstraint.new ) do
    get   '/:lang', :to => 'language#show', :format => false, :constraints => { :lang => /[^\/]+/ }

    get   '/:lang/:key/references',             :to => 'products#references', :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }, :as => 'product_references'
    get   '/:lang/:key/badge',                  :to => 'products#badge',      :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }, :as => 'product_badge'
    get   '/:lang/:key/:version/badge',         :to => 'products#badge',      :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/ }, :as => 'product_version_badge'

    get   '/:lang/:key/visual_dependencies'         , :to => 'products#show_visual', :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }
    get   '/:lang/:key/:version/visual_dependencies', :to => 'products#show_visual', :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/ }, :as => 'visual_dependencies'

    get   '/:lang/:key'                      , :to => 'products#show', :as => 'products',        :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }
    get   '/:lang/:key/edit'                 , :to => 'products#edit',                           :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }, :as => 'product_edit'
    get   '/:lang/:key/edit_links'           , :to => 'products#edit_links',                     :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }, :as => 'product_edit_links'
    get   '/:lang/:key/edit_licenses'        , :to => 'products#edit_licenses',                  :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }, :as => 'product_edit_licenses'
    post  '/:lang/:key/update'               , :to => 'products#update',                         :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }
    post  '/:lang/:key/delete_link'          , :to => 'products#delete_link',                    :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }
    post  '/:lang/:key/delete_license'       , :to => 'products#delete_license',                 :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/ }
    get   '/:lang/:key/:version'             , :to => 'products#show', :as => "package_version", :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/ }
    post  '/:lang/:key/:version/dependencies', :to => 'dependency_wheel#recursive_dependencies', :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/ }
    get   '/:lang/:key/:version/dependencies', :to => 'dependency_wheel#recursive_dependencies', :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/ }
    get   '/:lang/:key/:version/:build'      , :to => 'products#show'                          , :constraints => { :lang => /[^\/]+/, :key => /[^\/]+/, :version => /[^\/]+/, :build => /[^\/]+/ }
  end

  # get   '*path',        :to => 'page#routing_error'

end
