Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :auth do
    namespace :v1 do
      match 'control_plane_sso', to: 'control_plane_sso#create', via: [:get, :post]
      delete 'control_plane_sso', to: 'control_plane_sso#destroy'
    end

    # Add routes for success and error pages
    get 'success', to: 'pages#success'
    get 'error', to: 'pages#error'
  end

  # Add a protected resource route for testing
  namespace :api do
    namespace :v1 do
      get '/protected-resource', to: 'protected_resource#show'
    end
  end
end
