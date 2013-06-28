#require_relative '../app/api/v1/versioneye'

Versioneye::Application.routes.draw do

  mount V1::Versioneye::API => '/api'

  root :to => "products#index"

  get   '/auth/github/callback',   :to => 'github#callback'
  get   '/auth/github/new',        :to => 'github#new'
  post  '/auth/github/create',     :to => 'github#create'

  get   '/auth/twitter/forward',   :to => 'twitter#forward'
  get   '/auth/twitter/callback',  :to => 'twitter#callback'
  get   '/auth/twitter/new',       :to => 'twitter#new'
  post  '/auth/twitter/create',    :to => 'twitter#create'

  get   '/auth/facebook/callback', :to => 'facebook#callback'

  get   '/cloudcontrol/resources', :to => 'cloudcontrol#resources'


  resources :sessions, :only => [:new, :create, :destroy]
  get    '/signin',                :to => 'sessions#new'
  get    '/signout',               :to => 'sessions#destroy'


  get   '/users/christian.weyand',                    :to => redirect('/users/christianweyand')
  resources :users, :key => :username do
    member do
      get 'favoritepackages'
      get 'comments'
      get 'users_location'
    end
  end
  get   '/created', :to => 'users#created'
  get   '/signup',                       :to => 'users#new'
  get   '/users/activate/:verification', :to => 'users#activate'
  get   '/iforgotmypassword',            :to => 'users#iforgotmypassword'
  post  '/resetpassword',                :to => 'users#resetpassword'
  get   '/updatepassword/:verification', :to => 'users#show_update_password'
  post  '/updatepassword',               :to => 'users#update_password'
  get   '/home',                         :to => 'users#home'


  namespace :settings do

    get  'profile'             , :to => 'profile#index'
    post 'update_profile'      , :to => 'profile#update'

    get  'links'               , :to => 'links#index'
    post 'update_links'        , :to => 'links#update'

    get  'emails'              , :to => 'emails#index'
    post 'add_email'           , :to => 'emails#add_email'
    post 'delete_email'        , :to => 'emails#delete_email'
    post 'make_email_default'  , :to => 'emails#make_email_default'

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

    get  'payments'            , :to => 'payments#index'
    get  'receipt/:invoice_id' , :to => 'payments#receipt', :as => 'receipt'

  end

  resources :versioncomments
  get   '/vc/:id', :to => 'versioncomments#show'

  resources :versioncommentreplies

  get '/user/packages/popular_in_my_projects', :to => "user/packages#popular_in_my_projects"
  get '/user/packages/i_follow'              , :to => "user/packages#i_follow"
  get '/user/projects/github_repositories'   , :to => 'user/github_repos#init'

  namespace :user do
    resources :projects do
      member do
        get  'badge'
        post 'save_period'
        post 'save_email'
        post 'save_visibility'
        post 'reparse'
        post 'update_name'
      end
    end
    resources :github_repos
    get '/menu/github_repos', :to => 'github_repos#show_menu_items'
    get '/poll/github_repos', :to => 'github_repos#poll_changes'
  end

  post  '/services/choose_plan',  :to => 'services#choose_plan'
  resources :services do
    member do
      get  'recursive_dependencies'
      post 'recursive_dependencies'
    end
  end
  get   '/pricing',            :to => 'services#pricing'
  get   '/news',               :to => 'news#news'
  get   '/mynews',             :to => 'news#mynews'
  get   '/hotnews',            :to => 'news#hotnews'

  namespace :admin do
    resources :submitted_urls do
      post '/approve',            :to => 'submitted_urls#approve'
      post '/decline',            :to => 'submitted_urls#decline'
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
  get   '/imprint',             :to => 'page#imprint'
  get   '/nutzungsbedingungen', :to => 'page#nutzungsbedingungen'
  get   '/terms',               :to => 'page#terms'
  get   '/datenschutz',         :to => 'page#datenschutz'
  get   '/dataprivacy',         :to => 'page#dataprivacy'
  get   '/datenerhebung',       :to => 'page#datenerhebung'
  get   '/datacollection',      :to => 'page#datacollection'
  get   '/disclaimer',          :to => 'page#disclaimer'
  get   '/logos',               :to => 'page#logos'


  get   '/api',                 :to => 'swaggers#index'
  get   '/swaggers',            :to => redirect('/api')
  get   '/apijson',             :to => redirect('/api')
  get   '/apijson_tools',       :to => redirect('/api')
  get   '/apijson_libs',        :to => redirect('/api')

  get   '/newest/version',      :to => 'page#newest'
  get   '/current/version',     :to => 'page#newest'
  get   '/latest/version',      :to => 'page#newest'

  get   'sitemap_00_1.xml',        :to => 'page#sitemap_1'
  get   'sitemap_00_2.xml',        :to => 'page#sitemap_2'
  get   'sitemap_00_3.xml',        :to => 'page#sitemap_3'
  get   'sitemap_00_4.xml',        :to => 'page#sitemap_4'

  # Legacy paths. Keep them alive for Google
  get   '/docs/VersionEye_NUTZUNGSBEDINGUNGEN_de_V1.0.pdf', :to => redirect("/docs/VersionEye_NUTZUNGSBEDINGUNGEN_de_V1.1.pdf")
  get   '/product/symfony--symfony'                       , :to => redirect("/php/php:symfony:symfony")
  get   '/package/symfony--symfony'                       , :to => redirect("/php/php:symfony:symfony")
  get   '/package/symfony--symfony/version/:version'      , :to => redirect('/php/php:symfony:symfony/%{version}')
  get   '/product/symfony--symfony/version/:version'      , :to => redirect('/php/php:symfony:symfony/%{version}')

  get   '/search', :to => 'products#search'

  get   '/package/name'        , :to => 'products#autocomplete_product_name'
  post  '/package/follow'      , :to => 'products#follow'
  post  '/package/unfollow'    , :to => 'products#unfollow'
  post  '/package/image_path'  , :to => 'dependency_wheel#image_path'
  post  '/package/upload_image', :to => 'dependency_wheel#upload_image'


  get   '/package_visual/:key'                 , :to => 'products#show_visual_old', :constraints => { :key => /[^\/]+/ }
  get   '/package_visual/:key/version/:version', :to => 'products#show_visual_old', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/package_visual/:key/:version'        , :to => 'products#show_visual_old', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  # TODO rewrite old routes for /package/:key/:version/badge to new paths
  get   '/:lang/:key/badge',                  :to => 'products#badge',  :constraints => { :key => /[^\/]+/ }
  get   '/:lang/:key/:version/badge',         :to => 'products#badge',  :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  # TODO rewrite old routes for /package_visual/:key/:version to new paths
  get   '/:lang/:key/visual_dependencies'         , :to => 'products#show_visual', :constraints => { :key => /[^\/]+/ }
  get   '/:lang/:key/:version/visual_dependencies', :to => 'products#show_visual', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  get   '/:lang/:key'                      , :to => 'products#show', :as => 'products', :constraints => { :key => /[^\/]+/ }
  get   '/:lang/:key/edit'                 , :to => 'products#edit',                    :constraints => { :key => /[^\/]+/ }
  post  '/:lang/:key/update'               , :to => 'products#update',                  :constraints => { :key => /[^\/]+/ }
  post  '/:lang/:key/delete_link'          , :to => 'products#delete_link',             :constraints => { :key => /[^\/]+/ }
  get   '/:lang/:key/:version'             , :to => 'products#show', :as => "package_version", :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  post  '/:lang/:key/:version/dependencies', :to => 'dependency_wheel#recursive_dependencies', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }
  get   '/:lang/:key/:version/dependencies', :to => 'dependency_wheel#recursive_dependencies', :constraints => { :key => /[^\/]+/, :version => /[^\/]+/ }

  #default action
  get   '*path',        :to => 'page#routing_error'

end
