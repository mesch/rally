require 'subdomain'

Rally::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  
  # User
  controller :user do
    scope :via => :get do
      match '/' => :home
      match :home
      match :connect
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
      match '/deal/:id' => :deal, :as => :deal
      match :coupons
      match '/coupon/:id' => :coupon, :as => :coupon
      match :share
      match :fb_share
      match :confirm_permissions
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
      match :fb_share      
      #match '/share' => :create_share, :as => :create_share
      #match '/share/:id' => :update_share, :as => :update_share
    end
  end
  
  # Payments
  namespace :payment do
    match '/order'          =>  :order,           :via => :get
    match '/order'          =>  :order,           :via => :post    
    match '/purchase'       =>  :purchase,        :via => :get
    match '/relay_response' =>  :relay_response,  :via => :post
    match '/receipt'        =>  :receipt,         :via => :get
  end
  
  # Facebook
  namespace :facebook do
    scope :via => :get do
      match '/' => :home
      match :home
      match :splash
      match :connect
      match :login
      match :logout
      match :deals
      match '/deal/:id' => :deal, :as => :deal
      match :coupons
      match '/coupon/:id' => :coupon, :as => :coupon
      match :share
      match :fb_share
      match :confirm_permissions
    end
    scope :via => :post do
      match '/' => :home
      match :home
      match :splash
      match :login
      match :fb_share
      #match '/share' => :create_share, :as => :create_share
      #match '/share/:id' => :update_share, :as => :update_share
    end
  end
  
  # Facebook Payments
  namespace :facebook_payment do
    match '/order'          =>  :order,           :via => :get
    match '/order'          =>  :order,           :via => :post    
    match '/purchase'       =>  :purchase,        :via => :get
    match '/relay_response' =>  :relay_response,  :via => :post
    match '/receipt'        =>  :receipt,         :via => :get
  end
  
  # General Site
  controller :site do
    match '/contact' => :contact, :via => :get
    match '/terms' => :terms, :via => :get
    match '/privacy' => :privacy, :via => :get
    match '/merchant_terms' => :merchant_terms, :via => :get
  end

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
      match :accept_terms
      match :account
      match :change_email
      match :change_password
      match :forgot_password
      match :deals
      match '/deal' => :new_deal, :as => :new_deal
      match '/deal/:id' => :edit_deal, :as => :edit_deal
      match '/deal/publish/:id' => :publish_deal, :as => :publish_deal
      match '/deal/delete/:id' => :delete_deal, :as => :delete_deal
      match '/deal/tip/:id' => :tip_deal, :as => :tip_deal
      match :connect
      match :connect_success
    end
    scope :via => :post do
      match :home
      match :login
      match :signup
      match :reactivate
      match :accept_terms
      match :change_email
      match :change_password
      match :forgot_password
      match '/deal' => :create_deal, :as => :create_deal
      match '/deal/:id' => :update_deal, :as => :update_deal
      match :connect
    end
    scope :via => :put do
      match :account
    end      
  end

  # Admin
  namespace :admin do
    match '/' => :home, :via => :get
    match :home, :via => :get
    resources :merchants do
      get 'change_password', :on => :member
      post 'change_password', :on => :member
      get 'send_activation', :on => :member
      get 'impersonate', :on => :member
      get 'reports', :on => :member
      get 'new_report', :on => :member
      post 'create_report', :on => :member
      get 'delete_report', :on => :member
    end
    resources :users
    resources :deals do
      get 'deal_codes', :on => :member
    end
    resources :coupons
    resources :orders
    resources :payments
    resources :process_logs
    resources :visitors
    resources :user_actions
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
=end
end
