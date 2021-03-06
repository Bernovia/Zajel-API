require 'sidekiq/web'

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_interslice_session"

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_AUTH_USERNAME"])) &
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_AUTH_PASSWORD"]))
  end if Rails.env.production?

  mount Sidekiq::Web => '/sidekiq'

  devise_for :users
  devise_for :admins
  namespace :api, defaults: { format: 'json' }, path: '/api' do
    mount_devise_token_auth_for 'User', at: 'auth', :controllers => { :passwords => "api/passwords" }
    resources :users do
      put :confirm, on: :collection
      get :re_send, on: :collection
    end
    resources :books do
      get 'by_name/:friendly_id', to: 'books#show', on: :collection
    end
    resources :mock_books, only: [:index]
    resources :my_books, only: [:index]
    resources :genres
    resources :book_activities

    resources :conversations, only: [:show] do
      resources :messages
    end

    resources :notifications do
      get :unread, on: :collection
      put :read, on: :collection
    end

    get 'metadata', to: 'metadata#index'

    namespace :admin, defaults: { format: 'json' } do
      mount_devise_token_auth_for 'Admin', at: 'auth'

      resources :books
      resources :book_activities
      resources :users
      resources :genres, only: [:index, :create, :update]
      resources :languages, only: [:index, :create, :update]
      resources :metadata, only: [:index]
      resources :requests, only: [:index]
    end
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
