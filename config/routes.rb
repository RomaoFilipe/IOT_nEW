Rails.application.routes.draw do
  # Configuração do Devise para o sistema de autenticação
  devise_for :users
  resources :users, only: [:index, :edit, :update, :destroy]
  resources :tasks, only: [:index, :create, :update, :destroy]
  resources :profiles, only: [:show, :edit, :update]
  resources :fields, only: [:create, :index, :destroy, :show]


  # Define a rota do Devise para o login
  devise_scope :user do
    root to: 'devise/sessions#new' # Redireciona a rota raiz para a página de login
  end

  # Rota para a página "home" após o login
  get '/home', to: 'home#index', as: 'home'

  # Rota para a página de analytics
  get '/analytics', to: 'analytics#index', as: 'analytics'

  

  get 'profile/:id', to: 'profiles#show', as: 'user_profile'

  # Rotas para o gerenciamento de usuários (somente para o admin)
  resources :users, only: [:index]

  get 'admin_dashboard', to: 'users#admin_dashboard', as: 'admin_dashboard'

  get 'users/:id/entrar_como', to: 'users#entrar_como', as: 'entrar_como_user'
  delete 'retornar_como_admin', to: 'users#retornar_como_admin', as: 'retornar_como_admin'


end
