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

    # ✅ Administração de utilizadores
    resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      post :entrar_como, on: :member
      post :retornar_como_admin, on: :collection
    end


    # 🌾 Gestão de dados agrícolas
    resources :tasks, only: [ :index, :create, :update, :destroy ]
    resources :crop_yields, only: [ :create ]
    resources :soil_readings, only: [ :create ]
    resources :financials, only: [ :create ]
    resources :planned_tasks, only: [ :destroy ]
    resources :irrigation_schedules, only: [ :destroy ]

    # 📡 Sensores (globais)
    resources :sensors, only: [ :create, :destroy, :update ] do
      post :simulate, on: :member
      post :stop_irrigation, on: :member
      post :start_irrigation, on: :member
      post "readings", to: "sensor_readings#create", on: :member
      patch :toggle_status, on: :member
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
          get :today # ✅ Ver agendamentos de hoje
        end
      end
    end
  end

  # 🌐 API pública e protegida (fora do `authenticate`)
  namespace :api do
    get "sensors/identify", to: "sensors#identify"
    get "sensors/find_by_device_id", to: "sensors#find_by_device_id"

    resources :sensors, only: [] do
      post :simulate, on: :member
      post "readings", to: "sensor_readings#create", on: :member
    end

    resources :irrigation_logs, only: [ :create ]
  end

  # 👤 Perfil
  get "profile/:id", to: "profiles#show", as: "user_profile"
end
