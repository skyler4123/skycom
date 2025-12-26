Rails.application.routes.draw do
  resources :statistics


  # Routes for Admin Management
  namespace :admin do
    # We use 'scope module: :admin
    # to tell Rails that the controllers for these resources are located inside the "Admin
    # namespace (e.g., app/controllers/admin/users_controller.rb).
    resources :dashboard
    resources :company_groups
    resources :companies
    resources :users
    resources :subscriptions
  end



  # Routes for Retail Management
  resources :retail, only: [ :show ] do
    # We use 'scope module: :retail' to tell Rails that the controllers
    # for these resources are located inside the "Retail::" namespace
    # (e.g., app/controllers/retail/stores_controller.rb).
    scope module: :retail do
      namespace :management do
        resources :dashboard
        resources :branches
        resources :departments
        resources :products
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
        resources :administrators
      end

      namespace :pos do
        resources :branches, only: [ :show ] do
          member do
            get :products
          end
        end
      end
    end
  end

  # Routes for School Management
  resources :education, only: [ :show ] do
    # We use 'scope module: :education' to tell Rails that the controllers
    # for these resources are located inside the "Education::" namespace
    # (e.g., app/controllers/education/schools_controller.rb).
    scope module: :education do
      resources :schools
      resources :courses
      resources :students
      resources :teachers
      resources :classes
      resources :schedules
    end
  end

  # Routes for Hospital Management
  resources :hospital do
    # We use 'scope module: :hospital' to tell Rails that the controllers
    # for these resources are located inside the "Hospital::" namespace
    # (e.g., app/controllers/hospital/patients_controller.rb).
    scope module: :hospital do
      resources :patients
      resources :doctors
      resources :appointments
      resources :medical_records
      resources :prescriptions
      resources :departments
      resources :staffs
      resources :billings
      resources :insurances
      resources :labs
      resources :pharmacies
    end
  end

  # General Application Routes
  resources :categories
  resources :article_appointments
  resources :article_group_appointments
  resources :articles
  resources :article_groups
  resources :document_appointments
  resources :document_group_appointments
  resources :documents
  resources :document_groups
  resources :setting_appointments
  resources :setting_group_appointments
  resources :setting_groups
  resources :subscription_appointments
  resources :subscriptions
  resources :event_appointments
  resources :event_group_appointments
  resources :events
  resources :event_groups
  resources :company_groups
  resources :exam_appointments
  resources :answers
  resources :questions
  resources :exams
  resources :exam_groups
  resources :notification_group_appointments
  resources :task_appointments
  resources :project_appointments
  resources :project_group_appointments
  resources :facility_appointments
  resources :purchase_items
  resources :purchases
  resources :order_appointments
  resources :order_group_appointments
  resources :order_groups
  resources :service_appointments
  resources :product_appointments
  resources :brands
  resources :inventory_transaction_appointments
  resources :inventory_transactions
  resources :inventory_item_appointments
  resources :inventory_items
  resources :inventories
  resources :customer_appointments
  resources :employee_appointments
  resources :notification_appointments
  resources :notifications
  resources :notification_groups
  resources :cart_appointments
  resources :carts
  resources :cart_groups
  resources :projects
  resources :project_groups
  resources :task_group_appointments
  resources :tasks
  resources :task_groups
  resources :bookings
  resources :customer_group_appointments
  resources :customer_groups
  resources :service_group_appointments
  resources :service_groups
  resources :product_group_appointments
  resources :product_groups
  resources :facility_group_appointments
  resources :facility_groups
  resources :payment_method_appointments
  resources :payment_methods
  resources :period_appointments
  resources :periods
  resources :payments
  resources :invoices
  resources :orders
  resources :customers
  resources :products
  resources :services
  resources :facilities
  resources :role_appointments
  resources :policy_appointments
  resources :policies
  resources :roles
  resources :employee_group_appointments
  resources :employees
  resources :employee_groups
  resources :tag_appointments
  resources :tags
  resources :companies
  resources :addresses
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
  # ----------------------------------------------------------------------------------------------------
  # DEFAULTS
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
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
