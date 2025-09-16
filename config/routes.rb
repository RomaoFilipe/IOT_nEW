# config/routes.rb
require "sidekiq/web"

Rails.application.routes.draw do
  scope "(:locale)", locale: /pt|en|es/ do
    # 🔐 Auth
    devise_for :users, controllers: { registrations: "users/registrations" }

    # 🏠 Público
    root to: "home#index"
    get "/home", to: "home#index", as: :home

    # 🔒 Área autenticada
    authenticate :user do
      # 🌍 Navegação principal
      get "dashboard", to: "dashboard#index", as: :dashboard
      # (REMOVIDO) get "settings" duplicado — o resource :settings já define GET /settings

      # 📈 Analytics
      get "analytics",        to: "analytics#index",  as: :analytics
      get "analytics/data",   to: "analytics#data",   as: :analytics_data,  defaults: { format: :json }
      get "analytics/export", to: "analytics#export", as: :export_analytics

      # 👑 OWNER - Gestão de contas
      namespace :admin do
        resources :accounts do
          member     { post :simulate }
          collection { delete :stop_simulation }
        end
        resources :production_facts
      end

      # 👥 Equipa (ADMIN/MANAGER)
      namespace :team do
        resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
          post :impersonate, on: :member
          collection { patch :update_account }
        end
      end
      post "/revert_impersonation", to: "team/users#revert_impersonation", as: :revert_impersonation

      # 👤 Utilizadores (geral da app, não Devise)
      resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
        get  :entrar_como,         on: :member
        post :retornar_como_admin, on: :collection
      end

      # 🌾 Campos & Sensores (aninhados em campo)
      resources :fields do
        resources :sensors, only: [:create, :destroy] do
          post  :simulate,      on: :member
          patch :toggle_status, on: :member
          patch :update_polygon
        end

        resources :irrigation_schedules, only: [:create, :destroy] do
          collection { get :today }
          get :by_sensor
        end
      end

      # Extras por domínio
      resources :agriculture_fields
      resources :aquaculture_tanks
      resources :aquaculture_seas

      # 🌱 Registos rápidos
      resources :tasks,         only: [:index, :create, :update, :destroy]
      resources :planned_tasks, only: [:destroy]
      resources :crop_yields,   only: [:create]
      resources :soil_readings, only: [:create]
      resources :financials,    only: [:create]

      # (rota global extra que já tinhas)
      resources :irrigation_schedules, only: [:destroy]
      get "irrigation_schedules/by_sensor", to: "irrigation_schedules#by_sensor", as: :irrigation_by_sensor

      # 🛰️ Sensores globais
      # Inclui :new para existir new_sensor_path
      resources :sensors, only: [:index, :show, :new, :create, :destroy, :update] do
        # Alguns membros apontam para controllers API (ok, se for intencional)
        post  :simulate,        to: "api/sensors#simulate",      as: :simulate_api
        patch :toggle_status,   to: "api/sensors#toggle_status", as: :toggle_status_api

        # Membros no controller web
	patch :assign_field,   on: :member
        patch :unassign_field,  on: :member
        post  :stop_irrigation, on: :member
        post  :start_irrigation,on: :member

        # Leituras
        post :readings,         to: "sensor_readings#create", on: :member
        get  :readings,         on: :member

        # Info
        get  :irrigation_history, on: :member
        get  :status_info,        on: :member

        collection { post :lookup }
      end

      # 📅 Eventos
      get "/events/upcoming",           to: "events#upcoming"
get "/dashboard/activity", to: "dashboard#activity_feed", as: :dashboard_activity
      get "/dashboard/upcoming_events", to: "dashboard#upcoming_events", as: :dashboard_upcoming_events

      # ⚙️ Configurações pessoais
      resource :settings, only: [:index] do
        patch :update_profile
        patch :update_notifications
        patch :update_password
      end

      # 🔎 Auxiliares
      get "sensors/:id/irrigation_status", to: "sensors#irrigation_status"
      get "fields/:id/show_details",       to: "fields#show_details", as: :show_field_details
    end

    # 👤 Perfil público
    get "profile/:id", to: "profiles#show", as: "user_profile"

    # 🌐 API
    namespace :api do
      get "sensors/identify",          to: "sensors#identify"
      get "sensors/find_by_device_id", to: "sensors#find_by_device_id"

      resources :sensors, only: [] do
        patch :toggle_status, on: :member
        post  :simulate,      on: :member
        post  :readings,      to: "sensor_readings#create", on: :member
      end

      post "sensors/register", to: "sensors#register"
      resources :irrigation_logs, only: [:create]
    end

    # 🌍 Idioma
    get "locale/:id", to: "locales#update", as: :switch_locale
  end

  # 📡 WebSockets
  mount ActionCable.server => "/cable"

  # ✅ Sidekiq (admins)
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end
end
