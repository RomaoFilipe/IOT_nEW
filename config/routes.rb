require 'sidekiq/web'

Rails.application.routes.draw do
  scope "(:locale)", locale: /pt|en|es/ do

    # 🔐 Autenticação com Devise
    devise_for :users, controllers: {
      registrations: "users/registrations"
    }

    # 🏠 Página pública (Landing Page)
    root to: "home#index"
    get "/home", to: "home#index", as: :home

    # 🔒 Área autenticada
    authenticate :user do

      # 🌍 Navegação principal
      get "dashboard", to: "dashboard#index", as: :dashboard
      get "/analytics", to: "analytics#index", as: :analytics
      get "/settings", to: "settings#index", as: :settings

      # 👑 OWNER - Gestão de contas
      namespace :admin do
        resources :accounts do
          member { post :simulate }
          collection { delete :stop_simulation }
        end
      end

      # 👥 Gestão de equipa (ADMIN/MANAGER)
      namespace :team do
        resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
          post :impersonate, on: :member
          collection { patch :update_account }
        end
      end
      post "/revert_impersonation", to: "team/users#revert_impersonation", as: :revert_impersonation

      # 👤 Utilizadores (geral)
      resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
        get :entrar_como, on: :member
        post :retornar_como_admin, on: :collection
      end

      # 🌾 Campos agrícolas e aquacultura
      resources :fields, only: [:index, :show, :new, :create, :destroy] do
        resources :sensors, only: [:create, :destroy] do
          post :simulate, on: :member
          patch :toggle_status, on: :member
        end
      end

      resources :fields do
        resources :irrigation_schedules, only: [:create, :destroy] do
          collection { get :today }
          get :by_sensor 
        end
      end

      resources :agriculture_fields
      resources :aquaculture_tanks
      resources :aquaculture_seas

      # 🌱 Dados agrícolas
      resources :tasks, only: [:index, :create, :update, :destroy]
      resources :planned_tasks, only: [:destroy]
      resources :crop_yields, only: [:create]
      resources :soil_readings, only: [:create]
      resources :financials, only: [:create]
      resources :irrigation_schedules, only: [:destroy]

      # 🛰️ Sensores globais
      resources :sensors, only: [:create, :destroy, :update] do
        post :simulate, to: "api/sensors#simulate", as: :simulate_api
        patch "/sensors/:id/toggle_status", to: "api/sensors#toggle_status", as: :toggle_status_api
        patch :unassign_field, on: :member
        post :stop_irrigation, on: :member
        post :start_irrigation, on: :member
        post "readings", to: "sensor_readings#create", on: :member
        patch :assign_field, on: :member
        patch :update_status, on: :member
        get :readings, on: :member
        get :irrigation_history, on: :member
        get :status_info, on: :member
        collection { post :lookup }
      end

      get "irrigation_schedules/by_sensor", to: "irrigation_schedules#by_sensor", as: :irrigation_by_sensor


      # 📅 Eventos e previsões
      get "/events/upcoming", to: "events#upcoming"
      get "/dashboard/upcoming_events", to: "dashboard#upcoming_events", as: :dashboard_upcoming_events

      # 📈 Exportações Analytics
      get 'analytics/export_csv', to: 'analytics#export_csv', as: 'export_analytics_csv'
      get 'analytics/export_field_comparison_csv', to: 'analytics#export_field_comparison_csv', as: 'export_field_comparison_csv'
      get 'analytics/export_irrigation_efficiency_csv', to: 'analytics#export_irrigation_efficiency_csv', as: 'export_irrigation_efficiency_csv'

      # ⚙️ Configurações pessoais
      resource :settings, only: [:index] do
        patch :update_profile
        patch :update_notifications
        patch :update_password
      end

      # 🔎 Endpoints auxiliares
      get 'sensors/:id/irrigation_status', to: 'sensors#irrigation_status'
      get 'fields/:id/show_details', to: 'fields#show_details', as: 'show_field_details'
    end

    # 👤 Perfil individual
    get "profile/:id", to: "profiles#show", as: "user_profile"

    # 🌐 API pública/protegida
    namespace :api do
      get "sensors/identify", to: "sensors#identify"
      get "sensors/find_by_device_id", to: "sensors#find_by_device_id"

      resources :sensors, only: [] do
        patch :toggle_status, on: :member
        post :simulate, on: :member
        post "readings", to: "sensor_readings#create", on: :member
      end
      post "sensors/register", to: "sensors#register"
      resources :irrigation_logs, only: [:create]
    end

    # 🌍 Localização (idioma)

get 'locale/:id', to: 'locales#update', as: :switch_locale
  end

  # 📡 WebSockets
  mount ActionCable.server => "/cable"

  # ✅ Painel de Background Jobs (Sidekiq)
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end
end
