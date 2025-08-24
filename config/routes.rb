Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users
  ActiveAdmin.routes(self)
  # Marketing requests routes
  resources :marketing, path: "marketing" do
    member do
      patch :activate
      patch :reject
      patch :transfer
    end
  end
  get "heatmap", to: "heatmap#index", as: :heatmap

  # Settings routes
  namespace :settings do
    resources :templates, controller: "bonus_templates"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Bonus management routes
  resources :bonuses do
    member do
      get :preview
      post :duplicate
    end
    collection do
      get :by_type
      post :bulk_update
      get :find_template
    end
  end

  # API routes for bonus management
  namespace :api do
    namespace :v1 do
      resources :bonuses, only: [ :index, :show, :create, :update, :destroy ] do
        collection do
          get :by_type
          get :active
          get :expired
        end
      end
    end
  end

  # Defines the root path route ("/")
  root "bonuses#index"
end
