# frozen_string_literal: true

Rails.application.routes.draw do
  # Root route - redirect based on authentication
  root to: "home#index"

  # Authentication routes
  get 'login', to: 'auth#login'
  delete 'logout', to: 'auth#logout'
  
  # VoipAppz authentication routes
  get 'auth/callback', to: 'auth#voipappz_callback'
  get 'auth/failure', to: 'auth#failure'

  # Main application routes (require authentication)
  get 'dashboard', to: 'dashboard#index'
  get 'live', to: 'dashboard#live'
  
  resources :calls do
    member do
      get 'recordings'
    end
  end
  
  resources :reports, only: [:index] do
    collection do
      get :calls
    end
  end
  
  resources :users, only: [:index, :show, :update] do
    member do
      patch :change_role
      patch :toggle_active
    end
  end

  # API routes
  namespace :api, format: :json do
    # VoipAppz authentication routes
    namespace :auth do
      post 'verify', to: 'sessions#verify_token'
      get 'me', to: 'sessions#show'
      post 'refresh', to: 'sessions#refresh_token'
      delete 'sign_out', to: 'sessions#destroy'
    end

    # Organization management
    resources :organizations, only: [:show, :update] do
      member do
        get :stats
      end
      
      # Items within organizations
      resources :items do
        collection do
          get :count
        end
      end
    end

    # User management
    resources :users, only: [:show, :update, :index] do
      member do
        patch :change_role
        patch :toggle_active
      end
    end

    # Health check endpoint
    get 'health', to: 'application#health'
  end

  # WebSocket routes  
  mount ActionCable.server => "/cable"
end
