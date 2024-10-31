Rails.application.routes.draw do
  # Configuração do Devise para o sistema de autenticação
  devise_for :users
  resources :tasks, only: [:index, :create]



  # Define a rota do Devise para o login
  devise_scope :user do
    root to: 'devise/sessions#new' # Redireciona a rota raiz para a página de login
  end

  # Rota para a página "home" após o login
  get '/home', to: 'home#index', as: 'home'

  # Rota para a página de analytics
  get '/analytics', to: 'analytics#index', as: 'analytics'

  # Rota para o calendário
  get '/calendar', to: 'calendar#index', as: 'calendar'
end
