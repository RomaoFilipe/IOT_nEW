require 'sidekiq/web'

Rails.application.routes.draw do
  scope "(:locale)", locale: /pt|en|es/ do
  # 🔐 Devise (com controlador custom para registos se usares)
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # 🏠 Página pública (landing page)
  root to: "home#index"
  get "/home", to: "home#index", as: "home"

  # 🔒 Área protegida (após login)
  authenticate :user do
    # 🧭 Navegação principal
    get "dashboard", to: "dashboard#index", as: :dashboard
    get "/analytics", to: "analytics#index", as: "analytics"
    get "/settings", to: "settings#index", as: "settings"

    # ✅ OWNER - ver todas as contas e simular
    namespace :admin do
      resources :accounts do
        member do
          post :simulate           # /admin/accounts/:id/simulate
        end
        collection do
          delete :stop_simulation  # /admin/accounts/stop_simulation
        end
      end
    end


    # ✅ ADMIN / MANAGER - gerir equipa da conta
namespace :team do
  resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
    post :impersonate, on: :member
    collection do
      patch :update_account
    end
  end
end
    post "/revert_impersonation", to: "team/users#revert_impersonation", as: :revert_impersonation

    # ✅ Utilizadores (geral - para owner ou painel admin)
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy] do
      get :entrar_como, on: :member
      post :retornar_como_admin, on: :collection
    end

    # ✅ Campos agrícolas
    resources :fields, only: [:index, :show, :new, :create, :destroy] do
      resources :sensors, only: [:create, :destroy] do
        post :simulate, on: :member
        patch :toggle_status, on: :member
      end
    end

    resources :fields do
      resources :irrigation_schedules, only: [:create, :destroy] do
        collection do
          get :today
        end
      end
    end

    

    # ✅ Dados agrícolas
    resources :tasks, only: [:index, :create, :update, :destroy]
    resources :planned_tasks, only: [:destroy]
    resources :crop_yields, only: [:create]
    resources :soil_readings, only: [:create]
    resources :financials, only: [:create]
    resources :irrigation_schedules, only: [:destroy]
    resources :agriculture_fields
    resources :aquaculture_tanks
    resources :aquaculture_seas




    # ✅ Sensores globais
    resources :sensors, only: [:create, :destroy, :update] do
      post :simulate, on: :member
      post :stop_irrigation, on: :member
      post :start_irrigation, on: :member
      post "readings", to: "sensor_readings#create", on: :member
      patch :toggle_status, on: :member
      patch :assign_field, on: :member
      patch :update_status, on: :member
      get :readings, on: :member
      get :irrigation_history, on: :member
      get :status_info, on: :member
      collection do
        post :lookup
      end
    end

    # 📅 Eventos e notificações
    get "/events/upcoming", to: "events#upcoming"
    get "/dashboard/upcoming_events", to: "dashboard#upcoming_events", as: :dashboard_upcoming_events

    # 📈 Exportações
    get 'analytics/export_csv', to: 'analytics#export_csv', as: 'export_analytics_csv'
    get 'analytics/export_field_comparison_csv', to: 'analytics#export_field_comparison_csv', as: 'export_field_comparison_csv'
    get 'analytics/export_irrigation_efficiency_csv', to: 'analytics#export_irrigation_efficiency_csv', as: 'export_irrigation_efficiency_csv'

    # ⚙️ Configurações pessoais
    resource :settings, only: [:index] do
      patch :update_profile
      patch :update_notifications
      patch :update_password
    end

    # 🛰️ Endpoints auxiliares
    get 'sensors/:id/irrigation_status', to: 'sensors#irrigation_status'
    get 'fields/:id/show_details', to: 'fields#show_details', as: 'show_field_details'
  end

    # ✅ Painel Sidekiq (fora do bloco anterior)
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # 🌐 API pública e protegida
  namespace :api do
    get "sensors/identify", to: "sensors#identify"
    get "sensors/find_by_device_id", to: "sensors#find_by_device_id"

    resources :sensors, only: [] do
      post :simulate, on: :member
      post "readings", to: "sensor_readings#create", on: :member
    end

    resources :irrigation_logs, only: [:create]
  end

  # 👤 Perfil individual
  get "profile/:id", to: "profiles#show", as: "user_profile"

  # Rota para alterar idioma
    put '/locale', to: 'settings#locale', as: :locale

end
  # 📡 WebSocket
  mount ActionCable.server => "/cable"
end
