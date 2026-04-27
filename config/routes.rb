# config/routes.rb

Rails.application.routes.draw do
  resources :client_cache, only: [ :index ]
  resources :redirect do
    collection do
      get :companies
    end
  end
  resources :demo, only: [ :index ] do
    collection do
      get :calendar_events
    end
  end
  resources :companies do
    scope module: :companies do
      resources :dashboards
      resources :branches
      resources :departments
      resources :products
      resources :services
      resources :orders
      resources :bookings
      resources :payments
      resources :employees
      resources :inventories
      resources :customers
      resources :invoices
      resources :schedules
      resources :attendances
      resources :reports
      resources :documents
      resources :announcements
      resources :discounts
      resources :events
      resources :payslips
      resources :tasks
      resources :facilities
      resources :settings
      resources :subscriptions
      resources :permissions
      resources :policies
      resources :policy_appointments
    end
  end

  resources :users do
    collection do
      patch :update_avatar
    end
  end
  resources :home, only: [ :index ] do
    collection do
      get :retail
      get :education
      get :hospital
      get :restaurant
      get :shop
      get :fitness
    end
  end
  mount MissionControl::Jobs::Engine, at: "/jobs"
  get "sign_out", to: "sessions#sign_out"
  get "/sign_in_for_test", to: "sessions#sign_in_for_test", as: :sign_in_for_test if Rails.env.test?
  # ----------------------------------------------------------------------------------------------------
  # DEFAULTS
  post "sign_in", to: "sessions#create"
  post "sign_up", to: "registrations#create"
  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
  end
  get  "/auth/failure",            to: "sessions/omniauth#failure"
  get  "/auth/:provider/callback", to: "sessions/omniauth#create"
  post "/auth/:provider/callback", to: "sessions/omniauth#create"
  namespace :sessions do
    resource :passwordless, only: [ :new, :edit, :create ]
  end
  resource :invitation, only: [ :new, :create ]
  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  # ----------------------------------------------------------------------------------------------------
end
