Rails.application.routes.draw do
  # Devise routes for users
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  # Admin routes
  namespace :admin do
    devise_for :admin_users, controllers: {
      sessions: 'admin/sessions'
    }
    
    root 'dashboard#index'
    resources :users, only: [:index, :show, :edit, :update]
    resources :patents, only: [:index, :show]
    resources :annual_fees, only: [:index, :show, :edit, :update]
    resources :sync_jobs, only: [:index, :show, :create] do
      member do
        patch :retry
      end
    end
    resources :notifications, only: [:index, :show]
  end

  # Root route
  root 'dashboard#index'

  # User dashboard and patent management
  get 'dashboard', to: 'dashboard#index'
  
  resources :patents, only: [:index, :show] do
    member do
      post :sync
    end
    
    resources :annual_fees, only: [:index, :show] do
      resources :fee_payments, only: [:new, :create, :show]
    end
    
    resources :patent_documents, only: [:index, :show] do
      member do
        get :download
      end
    end
  end

  # Annual fees management
  resources :annual_fees, only: [:index, :show] do
    member do
      patch :mark_paid
    end
  end

  # User profile and settings
  resources :users, only: [:show, :edit, :update] do
    member do
      post :sync_patents
      get :export_data
    end
  end

  # Notifications
  resources :notifications, only: [:index, :show] do
    member do
      patch :mark_read
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :patents, only: [:index, :show]
      resources :annual_fees, only: [:index, :show]
      post 'sync/user/:id', to: 'sync#sync_user'
      post 'sync/all', to: 'sync#sync_all'
    end
  end

  # Health check for Render
  get 'health', to: 'application#health'
end