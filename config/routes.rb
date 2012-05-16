Versioneye::Application.routes.draw do
  
  root :to => "products#index"
  
  match '/auth/github/callback',   :to => 'github#callback'
  match '/auth/github/new',        :to => 'github#new'
  match '/auth/github/create',     :to => 'github#create'
  match '/auth/facebook/callback', :to => 'facebook#callback'
  get   '/auth/twitter/forward',   :to => 'twitter#forward'
  get   '/auth/twitter/callback',  :to => 'twitter#callback'
  match '/auth/twitter/new',       :to => 'twitter#new'
  match '/auth/twitter/create',    :to => 'twitter#create'

  match '/packagelike/like_overall',    :to => 'productlikes#like_overall'
  match '/packagelike/dislike_overall', :to => 'productlikes#dislike_overall'
  match '/packagelike/like_docu',       :to => 'productlikes#like_docu'
  match '/packagelike/dislike_docu',    :to => 'productlikes#dislike_docu'
  match '/packagelike/like_support',    :to => 'productlikes#like_support'
  match '/packagelike/dislike_support', :to => 'productlikes#dislike_support'

  resources :products 
  match '/autocomplete_product_name',                   :to => 'products#autocomplete_product_name'
  match '/search',                                      :to => 'products#search'
  match '/follow',                                      :to => 'products#follow'
  match '/unfollow',                                    :to => 'products#unfollow'
  match '/product/:key',                                :to => 'products#show'
  match '/package/:key',                                :to => 'products#show'
  match '/product/:key/version/:version',               :to => 'products#show'
  match '/package/:key/version/:version',               :to => 'products#show'
  match '/product/:key/version/:version/:uid',          :to => 'products#show'
  match '/product/newest/:key/:type',                   :to => 'products#newest'
  match '/product/wouldbenewest/:key/version/:version', :to => 'products#wouldbenewest'
  match '/biggest/:version1/:version2',                 :to => 'products#biggest'


  match '/news',               :to => 'news#news'
  match '/mynews',             :to => 'news#mynews'
  match '/hotnews',            :to => 'news#hotnews'
  
  resources :users, :key => :username do 
    member do 
      get 'favoritepackages'
      get 'comments'
      match 'name'
    end
  end
  match '/signup',                       :to => 'users#new'
  match '/users/:id/notifications',      :to => 'users#notifications'
  match '/users/activate/:verification', :to => 'users#activate'
  match '/iforgotmypassword',            :to => 'users#iforgotmypassword'
  match '/resetpassword',                :to => 'users#resetpassword'
  match '/home',                         :to => 'users#home'
    
  get  '/settings/profile',            :to => 'settings#profile'
  get  '/settings/name',               :to => 'settings#name'
  get  '/settings/password',           :to => 'settings#password'
  get  '/settings/privacy',            :to => 'settings#privacy'
  get  '/settings/delete',             :to => 'settings#delete'
  get  '/settings/links',              :to => 'settings#links'
  post '/settings/updatenames',        :to => 'settings#updatenames'
  post '/settings/updatepassword',     :to => 'settings#updatepassword'
  post '/settings/updateprivacy',      :to => 'settings#updateprivacy'
  post '/settings/updateprofile',      :to => 'settings#updateprofile'
  post '/settings/updatelinks',        :to => 'settings#updatelinks'
  post '/settings/destroy',            :to => 'settings#destroy'

  resources :versioncomments
  match '/vc/:id',              :to => 'versioncomments#show'

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
  match '/signin',                :to => 'sessions#new'
  match '/signout',               :to => 'sessions#destroy'
  match '/androidregistrationid', :to => 'sessions#android_registrationid'
  
  match '/blogs/show/:key/:id',        :to => 'blogs#show', :as => :showblog
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
  match '/crawles',             :to => 'crawles#index'
  match '/group/:group',        :to => 'crawles#group'

  match '/feedback',            :to => 'feedback#feedback'    

  match '/about',               :to => 'page#about'
  match '/impressum',           :to => 'page#impressum'
  match '/imprint',             :to => 'page#imprint'
  match '/nutzungsbedingungen', :to => 'page#nutzungsbedingungen'  
  match '/terms',               :to => 'page#terms'
  match '/datenschutz',         :to => 'page#datenschutz'
  match '/dataprivacy',         :to => 'page#dataprivacy'
  match '/datenerhebung',       :to => 'page#datenerhebung'
  match '/datacollection',      :to => 'page#datacollection'  
  match '/apijson',             :to => 'page#apijson'  
  match '/apijson_tools',       :to => 'page#apijson_tools'  
  match '/apijson_libs',        :to => 'page#apijson_libs'
  match '/newest/version',      :to => 'page#newest'
  match '/current/version',     :to => 'page#newest'
  match '/latest/version',      :to => 'page#newest'

  match '*path', :to => 'page#routing_error'
  
end