Rails.application.routes.draw do
  # Configuração do Devise
  devise_for :users

  # 🔹 Garante que a Home está acessível sem login
  root to: 'home#index'
  get '/home', to: 'home#index', as: 'home'

  # 🔹 Rotas protegidas (apenas para utilizadores autenticados)
  authenticate :user do
    get 'dashboard', to: 'dashboard#index'
    get '/analytics', to: 'analytics#index', as: 'analytics'
    get '/settings', to: 'settings#index', as: 'settings'
    resources :tasks, only: [:index, :create, :update, :destroy]
    resources :fields, only: [:index, :show, :new, :create, :destroy]
  end

  # 🔹 Perfil do utilizador
  get 'profile/:id', to: 'profiles#show', as: 'user_profile'

  # 🔹 Administração (somente admins)
  get 'admin_dashboard', to: 'users#admin_dashboard', as: 'admin_dashboard'
end
