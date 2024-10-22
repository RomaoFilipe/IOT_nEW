Rails.application.routes.draw do
  # Configuração do Devise para o sistema de autenticação
  devise_for :users


  # Define a rota do Devise para o login
  devise_scope :user do
    root to: 'devise/sessions#new' # Redireciona a rota raiz para a página de login
  end

  # Rota para a página "home" após o login
  get '/home', to: 'home#index', as: 'home'



  get 'calendar', to: 'tasks#index'
  resources :tasks, only: [:new, :create, :index]



  # Outras rotas que já tens no sistema

  # Rota para health check do sistema
  get "up" => "rails/health#show", as: :rails_health_check

  # Rotas para PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
