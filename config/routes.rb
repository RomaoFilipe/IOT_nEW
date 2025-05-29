Rails.application.routes.draw do
  # 🔐 Autenticação com Devise
  devise_for :users

  # 🏠 Página pública inicial
  root to: "home#index"
  get "/home", to: "home#index", as: "home"

  # 🔒 Áreas protegidas (após login)
  authenticate :user do
    get "dashboard", to: "dashboard#index"
    get "/analytics", to: "analytics#index", as: "analytics"
    get "/settings", to: "settings#index", as: "settings"
    get "admin_dashboard", to: "users#admin_dashboard", as: "admin_dashboard"

    # 🌾 Gestão de dados agrícolas
    resources :tasks, only: [ :index, :create, :update, :destroy ]
    resources :crop_yields, only: [ :create ]
    resources :soil_readings, only: [ :create ]
    resources :financials, only: [ :create ]
    resources :sensors, only: [ :create, :destroy, :update ]
    resources :planned_tasks, only: [ :destroy ]
    resources :irrigation_schedules, only: [ :destroy ]

    # 📡 Sensores (globais)
    resources :sensors do
      post :simulate, on: :member
      post "readings", to: "sensor_readings#create", on: :member
      post :stop_irrigation, on: :member
      patch :toggle_status, on: :member
      post :start_irrigation, on: :member
      patch :assign_field, on: :member
      get :readings, on: :member
      get :irrigation_history, on: :member
      get :status_info, on: :member
      collection do
        post :lookup
      end
    end

    resource :settings, only: [ :index ] do
      patch :update_profile
      patch :update_notifications
      patch :update_password
    end

    # 🗺️ Campos com sensores aninhados
    resources :fields, only: [ :index, :show, :new, :create, :destroy ] do
      resources :sensors, only: [ :create, :destroy ] do
        post :simulate, on: :member
        patch :toggle_status, on: :member
      end
    end





    resources :fields do
      resources :irrigation_schedules, only: [ :create, :destroy ] do
        collection do
          get :today # ✅ NOVO: Ver agendamentos de hoje
        end
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

    # ✅ Endpoint para receber logs de execução da irrigação
    resources :irrigation_logs, only: [ :create ]
  end


  # 👤 Perfil e administração
  get "profile/:id", to: "profiles#show", as: "user_profile"
end
