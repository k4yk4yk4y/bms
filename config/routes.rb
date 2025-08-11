Rails.application.routes.draw do
  get "heatmap", to: "heatmap#index", as: :heatmap
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
      patch :activate
      patch :deactivate
      get :preview
    end
    collection do
      get :by_type
      post :bulk_update
    end
  end

  # API routes for bonus management
  namespace :api do
    namespace :v1 do
      resources :bonuses, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :activate
          patch :deactivate
        end
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
