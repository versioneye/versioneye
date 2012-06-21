Versioneye::Application.routes.draw do
  
  root :to => "products#index"
  
  get   '/auth/github/callback',   :to => 'github#callback'
  get   '/auth/github/new',        :to => 'github#new'
  post  '/auth/github/create',     :to => 'github#create'
  
  get   '/auth/twitter/forward',   :to => 'twitter#forward'
  get   '/auth/twitter/callback',  :to => 'twitter#callback'
  get   '/auth/twitter/new',       :to => 'twitter#new'
  post  '/auth/twitter/create',    :to => 'twitter#create'

  get   '/auth/facebook/callback', :to => 'facebook#callback'

  get   '/packagelike/like_overall',    :to => 'productlikes#like_overall'
  get   '/packagelike/dislike_overall', :to => 'productlikes#dislike_overall'
  get   '/packagelike/like_docu',       :to => 'productlikes#like_docu'
  get   '/packagelike/dislike_docu',    :to => 'productlikes#dislike_docu'
  get   '/packagelike/like_support',    :to => 'productlikes#like_support'
  get   '/packagelike/dislike_support', :to => 'productlikes#dislike_support'

  resources :products
  get   '/autocomplete_product_name',                   :to => 'products#autocomplete_product_name'
  get   '/search',                                      :to => 'products#search'
  post  '/follow',                                      :to => 'products#follow'
  post  '/unfollow',                                    :to => 'products#unfollow'
  get   '/product/:key',                                :to => 'products#show'
  get   '/package/:key',                                :to => 'products#show'
  get   '/product/:key/version/:version',               :to => 'products#show'
  get   '/package/:key/version/:version',               :to => 'products#show'
  get   '/package_visual/:key/version/:version',        :to => 'products#show_visual'
  post  '/package/:key/version/:version/recursive_dependencies', :to => 'products#recursive_dependencies'
  post  '/product/:key/version/:version/recursive_dependencies', :to => 'products#recursive_dependencies'
  get   '/product/newest/:key/:type',                   :to => 'products#newest'
  get   '/product/wouldbenewest/:key/version/:version', :to => 'products#wouldbenewest'
  get   '/biggest/:version1/:version2',                 :to => 'products#biggest'
  post  '/get_image_path',                              :to => 'products#get_image_path'
  post  '/upload_image',                                :to => 'products#upload_image'


  get   '/news',               :to => 'news#news'
  get   '/mynews',             :to => 'news#mynews'
  get   '/hotnews',            :to => 'news#hotnews'
  
  resources :users, :key => :username do 
    member do 
      get 'favoritepackages'
      get 'comments'
    end
  end
  get   '/signup',                       :to => 'users#new'
  get   '/users/:id/notifications',      :to => 'users#notifications'
  get   '/users/activate/:verification', :to => 'users#activate'
  get   '/iforgotmypassword',            :to => 'users#iforgotmypassword'
  post  '/resetpassword',                :to => 'users#resetpassword'
  get   '/home',                         :to => 'users#home'
    
  get  '/settings/profile',              :to => 'settings#profile'
  get  '/settings/name',                 :to => 'settings#name'
  get  '/settings/password',             :to => 'settings#password'
  get  '/settings/privacy',              :to => 'settings#privacy'
  get  '/settings/delete',               :to => 'settings#delete'
  get  '/settings/links',                :to => 'settings#links'
  post '/settings/updatenames',          :to => 'settings#updatenames'
  post '/settings/updatepassword',       :to => 'settings#updatepassword'
  post '/settings/updateprivacy',        :to => 'settings#updateprivacy'
  post '/settings/updateprofile',        :to => 'settings#updateprofile'
  post '/settings/updatelinks',          :to => 'settings#updatelinks'
  post '/settings/destroy',              :to => 'settings#destroy'

  resources :versioncomments
  get   '/vc/:id',                       :to => 'versioncomments#show'

  resources :versioncommentreplies
  
  namespace :user do 
    resources :projects do
      member do
        get 'follow'
        get 'unfollow'
      end
    end
  end
  
  resources :sessions, :only => [:new, :create, :destroy]
  get    '/signin',                :to => 'sessions#new'
  delete '/signout',               :to => 'sessions#destroy'
  post   '/androidregistrationid', :to => 'sessions#android_registrationid'
  
  get   '/blogs/show/:key/:id',        :to => 'blogs#show', :as => :showblog
  resources :blogs do
    collection do
      get 'myposts'
      get 'unapproved'
    end
    member do 
      post 'approval'
    end
    resources :blogcomments
  end
  
  resources :crawles
  get   '/crawles',             :to => 'crawles#index'
  get   '/group/:group',        :to => 'crawles#group'

  post  '/feedback',            :to => 'feedback#feedback'    

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
  get   '/pricing',             :to => 'page#pricing'
  get   '/apijson',             :to => 'page#apijson'  
  get   '/apijson_tools',       :to => 'page#apijson_tools'  
  get   '/apijson_libs',        :to => 'page#apijson_libs'
  get   '/newest/version',      :to => 'page#newest'
  get   '/current/version',     :to => 'page#newest'
  get   '/latest/version',      :to => 'page#newest'

  get   'sitemap_2.xml',        :to => 'page#sitemap_2'

  get   '*path', :to => 'page#routing_error'
  
end