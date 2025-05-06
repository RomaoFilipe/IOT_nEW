Rails.application.routes.draw do
  # 🔐 Autenticação com Devise
  devise_for :users

  # 🏠 Página pública inicial
  root to: 'home#index'
  get '/home', to: 'home#index', as: 'home'

  # 🔒 Áreas protegidas (após login)
  authenticate :user do
    get 'dashboard', to: 'dashboard#index'
    get '/analytics', to: 'analytics#index', as: 'analytics'
    get '/settings', to: 'settings#index', as: 'settings'

    # 🌾 Gestão de dados agrícolas
    resources :tasks, only: [:index, :create, :update, :destroy]
    resources :crop_yields, only: [:create]
    resources :soil_readings, only: [:create]
    resources :financials, only: [:create]

    # 📡 Sensores (globais)
    resources :sensors, only: [:create, :destroy] do
      post :simulate, on: :member
      post "readings", to: "sensor_readings#create", on: :member
      patch :toggle_status, on: :member
      patch :assign_field, on: :member
      get :readings, on: :member
      collection do
        post :lookup
      end
    end

    # 🗺️ Campos com sensores aninhados
    resources :fields, only: [:index, :show, :new, :create, :destroy] do
      resources :sensors, only: [:create, :destroy] do
        post :simulate, on: :member
        patch :toggle_status, on: :member
      end
    end
  end

  # 🌐 API pública e protegida (FORA do `authenticate`)
  namespace :api do
    get "sensors/identify", to: "sensors#identify" # 👈 agora está acessível sem login
    get "sensors/find_by_device_id", to: "sensors#find_by_device_id"
    resources :sensors, only: [] do
      post :simulate, on: :member
      post "readings", to: "sensor_readings#create", on: :member
    end
  end


  # 👤 Perfil e administração
  get 'profile/:id', to: 'profiles#show', as: 'user_profile'
  get 'admin_dashboard', to: 'users#admin_dashboard', as: 'admin_dashboard'
end
