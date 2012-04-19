Versioneye::Application.routes.draw do
  
  root :to => "products#index"
  
  match '/auth/github/callback',   :to => 'github#callback'
  match '/auth/github/new',        :to => 'github#new'
  match '/auth/github/create',     :to => 'github#create'
  match '/auth/facebook/callback', :to => 'facebook#callback'
  get   '/auth/twitter/callback',  :to => 'twitter#callback', :as => 'callback'

  resources :products
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
    
  get  '/settings/name',               :to => 'settings#name'
  get  '/settings/password',           :to => 'settings#password'
  get  '/settings/privacy',            :to => 'settings#privacy'
  post '/settings/updatenames',        :to => 'settings#updatenames'
  post '/settings/updatepassword',     :to => 'settings#updatepassword'
  post '/settings/updateprivacy',      :to => 'settings#updateprivacy'

  resources :versioncomments
  match '/vc/:id',              :to => 'versioncomments#show'
  
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
  
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
