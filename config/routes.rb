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

  
  resources :sessions, :only => [:new, :create, :destroy]
  get    '/signin',                :to => 'sessions#new'
  get    '/signout',               :to => 'sessions#destroy'
  post   '/androidregistrationid', :to => 'sessions#android_registrationid'


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

  
  get   '/search',                                      :to => 'products#search'
  get   '/package/name',                                :to => 'products#autocomplete_product_name'
  post  '/package/follow',                              :to => 'products#follow'
  post  '/package/unfollow',                            :to => 'products#unfollow'
  post  '/package/image_path',                          :to => 'products#image_path'
  post  '/package/upload_image',                        :to => 'products#upload_image'
  get   '/package/:key',                                :to => 'products#show', :as => 'products'
  get   '/package/:key/edit',                           :to => 'products#edit'
  post  '/package/:key/update',                         :to => 'products#update'
  get   '/package/:key/version/:version',               :to => 'products#show'
  post  '/package/:key/version/:version/dependencies',  :to => 'products#recursive_dependencies'
  post  '/package/:key/version/:version/lp_dependencies',  :to => 'products#lp_dependencies'

  get   '/product/:key',                                :to => 'products#show'
  get   '/product/:key/version/:version',               :to => 'products#show'

  get   '/package_visual/:key/version/:version',        :to => 'products#show_visual'

  get   '/packagelike/like_overall',    :to => 'productlikes#like_overall'
  get   '/packagelike/dislike_overall', :to => 'productlikes#dislike_overall'
  get   '/packagelike/like_docu',       :to => 'productlikes#like_docu'
  get   '/packagelike/dislike_docu',    :to => 'productlikes#dislike_docu'
  get   '/packagelike/like_support',    :to => 'productlikes#like_support'
  get   '/packagelike/dislike_support', :to => 'productlikes#dislike_support'


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

  get   '/news',               :to => 'news#news'
  get   '/mynews',             :to => 'news#mynews'
  get   '/hotnews',            :to => 'news#hotnews'
  
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

  get   'sitemap01.xml',        :to => 'page#sitemap01'
  get   'sitemap02.xml',        :to => 'page#sitemap02'
  get   'sitemap03.xml',        :to => 'page#sitemap03'
  get   'sitemap04.xml',        :to => 'page#sitemap04'
  get   'sitemap05.xml',        :to => 'page#sitemap05'
  get   'sitemap06.xml',        :to => 'page#sitemap06'
  get   'sitemap07.xml',        :to => 'page#sitemap07'
  get   'sitemap08.xml',        :to => 'page#sitemap08'
  get   'sitemap09.xml',        :to => 'page#sitemap09'
  get   'sitemap10.xml',        :to => 'page#sitemap10'
  get   'sitemap11.xml',        :to => 'page#sitemap11'
  get   'sitemap12.xml',        :to => 'page#sitemap12'
  get   'sitemap13.xml',        :to => 'page#sitemap13'
  get   'sitemap14.xml',        :to => 'page#sitemap14'
  get   'sitemap15.xml',        :to => 'page#sitemap15'

  get   '*path', :to => 'page#routing_error'
  
end