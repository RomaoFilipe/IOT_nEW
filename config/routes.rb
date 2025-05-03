Rails.application.routes.draw do
  # Configuração do Devise
  devise_for :users

  # 🔹 Home acessível sem login
  root to: 'home#index'
  get '/home', to: 'home#index', as: 'home'

  # 🔹 Áreas protegidas (login necessário)
  authenticate :user do
    get 'dashboard', to: 'dashboard#index'
    get '/analytics', to: 'analytics#index', as: 'analytics'
    get '/settings', to: 'settings#index', as: 'settings'

    resources :tasks, only: [:index, :create, :update, :destroy]
    resources :crop_yields, only: [:create]
    resources :soil_readings, only: [:create]
    resources :financials, only: [:create]

    # ✅ Sensores globais
    resources :sensors, only: [:create, :destroy] do
      post :simulate, on: :member
      patch :toggle_status, on: :member
    end

    # ✅ Campos e sensores aninhados
    resources :fields, only: [:index, :show, :new, :create, :destroy] do
      resources :sensors, only: [:create, :destroy] do
        post :simulate, on: :member
        patch :toggle_status, on: :member
      end
    end

    # ✅ API externa (para simuladores e sensores reais)
    namespace :api do
      resources :sensors, only: [] do
        post :simulate, on: :member
        post "readings", to: "sensor_readings#create", on: :member
      end
    end
  end

  # 🔹 Perfil e Administração
  get 'profile/:id', to: 'profiles#show', as: 'user_profile'
  get 'admin_dashboard', to: 'users#admin_dashboard', as: 'admin_dashboard'
end
