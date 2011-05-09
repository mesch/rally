require 'subdomain'

Rally::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Merchant
  namespace :merchant do
    scope :via => :get do
      match '/' => :home
      match :home
      match :login
      match :logout
      match :signup
      match :activate
      match :reactivate
      match :account
      match :change_email
      match :change_password
      match :forgot_password
      match :deals
      match '/deal' => :new_deal, :as => :new_deal
      match '/deal/:id' => :edit_deal, :as => :edit_deal
    end
    scope :via => :post do
      match :home
      match :login
      match :signup
      match :reactivate
      match :account
      match :change_email
      match :change_password
      match :forgot_password
      match '/deal' => :create_deal, :as => :create_deal
      match '/deal/:id' => :update_deal, :as => :update_deal
    end
  end
  
  # Admin
  namespace :admin do
    match '/' => :home, :via => :get
    match :home, :via => :get
  end

  # User
  controller :user do
    match '/' => :home, :via => :get
    match :home, :via => :get
    match :login, :via => :get
    match :logout, :via => :get
    match :connect, :via => :get
    match :invite, :via => :get
  end
  
  controller :site do
    match 'tos' => :tos, :via => :get
  end
  
  root :to => "site#home"

=begin
  # API
  constraints(APISubdomain) do
    match '/' => "sites#home" # for now - will probably point to some help doc
    namespace :v1 do
      match '/' => "sites#home" # for now - will probably point to some help doc
      controller :clients do
        match '/clients/badges' => :badges, :via => :get
        match '/clients/feats' => :feats, :via => :get
      end
      controller :users do
        match '/users/badges' => :badges, :via => :get
        match '/users/feats' => :feats, :via => :get
      end
      controller :feats do
        match '/feats/log' => :log, :via => :post
      end
      controller :reports do
        match 'reports/client' => :client, :via => :get
        match 'reports/badges' => :badges, :via => :get
        match 'reports/feats' => :feats, :via => :get
      end
    end
  end
  
  # Admin
  namespace :admin do
    match '/', :to => "admin#index", :as => :home
    resources :clients do
      post 'multi_update', :on => :collection
      post 'generate_api_key', :on => :member
    end
  end

  # Public Site
  match '/privacy', :to => "application#privacy"
  match '/tos', :to => "application#tos"
  


=end
end
