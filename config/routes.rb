# config/routes.rb

Rails.application.routes.draw do
  namespace :mobile do
    get "sign_in", to: "sessions#new"
    post "sign_in", to: "sessions#create"
    delete "sign_out", to: "sessions#destroy"

    scope "companies/:company_id", as: :company, module: :companies,
          constraints: { company_id: /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i } do
      get "home", to: "home#index"
      get "notifications", to: "notifications#index"
      get "employee", to: "employees#show"
      get "attendance_month", to: "attendance_months#show"
      get "operations", to: "operations#index"
      get "operations/pos/:operation_id", to: "operations/pos#show", as: :pos
      get "operations/booking/:operation_id", to: "operations/booking#show", as: :booking
      get "operations/reception/:operation_id", to: "operations/reception#show", as: :reception
      get "operations/store_manager/:operation_id", to: "operations/store_manager#show", as: :store_manager
      get "operations/inventory/:operation_id", to: "operations/inventory#show", as: :inventory
      get "payroll/unlock", to: "payroll_unlocks#new", as: :payroll_unlock
      post "payroll/unlock", to: "payroll_unlocks#create"
      get "payroll", to: "payrolls#show"
      post "attendances", to: "attendances#create"
      resources :attendance_requests, only: %i[new create]
    end
  end
  namespace :admin do
    resources :companies
    resources :payment_methods
    resources :company_credits, only: %i[index]
    resources :promo_campaigns do
      member do
        post :run_now
        post :cancel
      end
    end
    resources :company_tickets, only: [ :index, :show ] do
      member do
        post :assign
        post :resolve
        post :close
        post :reopen
        post :comment
      end
    end
  end
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
  resources :companies, only: %i[new create show edit update] do
    scope module: :companies do
      resources :dashboards, only: [ :index ]
      resource :dashboard, only: [ :show, :update ]
      resources :branches
      resources :departments
      resources :categories
      resources :products
      resources :brands
      resources :suppliers
      resources :services
      resources :orders do
        member do
          get :receipt
        end
      end
      resources :kpi_configs, only: %i[index create update destroy]
      resources :performance, only: %i[index show]
      resources :transactions
      resources :employees
      resources :employee_groups, only: %i[index show new create edit update]
      resources :employee_profiles
      resources :employee_subprofiles
      resources :customer_profiles
      resources :customer_subprofiles
      resources :stocks
      resources :warehouses
      resources :stock_transfers do
        member do
          post :initiate
          post :receive
          post :cancel
        end
      end
      resources :stock_imports
      resources :stock_exports
      resources :stock_adjustments
      resources :stock_pendings, only: [ :index, :show, :new, :create, :edit, :update ] do
        member do
          post :release
          post :cancel
        end
      end
      resources :customers
      resources :invoices
      resources :purchases do
        member do
          post :advance
        end
      end
      resources :workflows
      resources :discount_groups do
        member do
          post :generate_codes
        end
      end
      resources :shift_templates
      resources :scheduled_shifts
      resources :attendance_configs
      resources :attendance_config_logs, only: [ :index, :show ]
      resources :attendance_logs
      resources :attendance_days
      resources :attendance_requests, only: %i[index show new create] do
        member do
          post :approve
          post :reject
        end
      end
      resources :attendance_months do
        collection do
          get :my
          post :collect
        end
      end
      resources :reports
      resources :documents
      resources :questions
      resources :exams do
        member do
          post :publish
          post :archive
          post :refresh_summary
        end
        resources :assignments, only: %i[index create], controller: "exam_assignments"
        resources :appointments, only: %i[index show], controller: "exam_appointments" do
          member do
            patch :grade
          end
        end
      end
      resources :my_exams, only: %i[index show] do
        member do
          post :start
        end
      end
      resources :my_exam_appointments, only: %i[show] do
        member do
          get :take
          patch :answer
          post :submit
        end
      end
      resources :folders, only: [ :index, :show, :create, :update, :destroy ]
      resources :stored_files, only: [ :index, :show, :create, :destroy ] do
        member do
          get :download
        end
      end
      resources :company_migrations do
        member do
          post :chunks
          patch :update_config
          post :dry_run
          post :approve
          post :rollback
        end
      end
      resources :imports do
        member do
          post :source_file
          post :dry_run
          post :approve
          post :rollback
        end
      end
      get "storage_statistics", to: "storage_statistics#index"
      resources :announcements
      resources :discounts
      resources :company_tickets do
        member do
          post :rate
        end
      end
      resources :company_ticket_comments, only: [ :create ]
      resources :company_ticket_logs, only: [ :index, :show ]

      resources :tickets do
        member do
          post :advance
          post :assign
        end
      end
      resources :ticket_comments, only: [ :create ]
      resources :ticket_logs, only: [ :index, :show ]
      resources :notifications, only: [ :index, :show ] do
        member do
          post :mark_read
        end
        collection do
          post :mark_all_read
          get :unread_count
        end
      end
      resource :notification_config, only: [ :show, :update ]
      resources :notification_tags
      resources :events
      resources :event_configs
      resources :event_config_logs, only: [ :index, :show ]
      get "calendar", to: "calendars#index"
      resources :payslips
      resources :tasks
      resources :facilities
      resources :company_settings, only: [ :index, :update ]
      resources :subscription_plan_appointments
      resources :permissions
      resources :roles
      resources :permission_logs, only: [ :index, :show ]
      resources :payment_method_appointments, only: [ :index, :edit, :update ]
      resources :policies
      resources :policy_appointments
      resources :property_mappings
      resources :table_configs
      resources :table_config_logs, only: [ :index, :show ]
      resources :operations, only: [ :index ] do
        member do
          get :launch
        end

        collection do
          get "pos/:operation_id", to: "operations/pos#show", as: :pos
          get "pos/:operation_id/customer_lookup", to: "operations/pos#customer_lookup", as: :pos_customer_lookup
          get "booking/:operation_id", to: "operations/booking#show", as: :booking
          post "booking/:operation_id/reservations", to: "operations/booking#create_reservation", as: :booking_reservations
          get "inventory/:operation_id", to: "operations/inventory#show", as: :inventory
          get "reception/:operation_id", to: "operations/reception#show", as: :reception
          post "reception/:operation_id/check_in", to: "operations/reception#check_in", as: :reception_check_in
          post "reception/:operation_id/advance", to: "operations/reception#advance", as: :reception_advance
          post "reception/:operation_id/parcels", to: "operations/reception#create_parcel", as: :reception_parcels
          post "reception/:operation_id/parcels/:parcel_id/notify", to: "operations/reception#notify_parcel", as: :reception_parcel_notify
          post "reception/:operation_id/parcels/:parcel_id/pick_up", to: "operations/reception#pick_up_parcel", as: :reception_parcel_pick_up
          post "reception/:operation_id/notify_host", to: "operations/reception#notify_host", as: :reception_notify_host
          get "store_manager/:operation_id", to: "operations/store_manager#show", as: :store_manager
        end
      end
      resources :operation_configs, only: %i[index show edit update]
      resources :branch_operation_appointments, only: %i[show edit update]
      resources :operation_warehouse_appointments, only: %i[show edit update]

      get "analytics", to: "analytics#index"
      resource :analytic, only: %i[show update], controller: :analytics

      resource :tax_config, only: %i[show update], controller: :tax_configs
      get "tax", to: "taxes#index"
      get "tax/summary", to: "taxes#summary"
      get "tax/invoices", to: "taxes#invoices"
      get "tax/purchases", to: "taxes#purchases"
      get "tax/stock_exports", to: "taxes#stock_exports"

      resource :payroll_config, only: %i[show update], controller: :payroll_configs
      get "payroll", to: "payrolls#index"
      get "payroll/my", to: "payrolls#my"
      get "payroll/summary", to: "payrolls#summary"
      get "payroll/payrolls", to: "payrolls#payrolls"
      get "payroll/payrolls/:id", to: "payrolls#show", as: :payroll_payroll
      post "payroll/generate", to: "payrolls#generate"
      patch "payroll/payrolls/:id", to: "payrolls#update", as: :payroll_payroll_update

      # PLACEHOLDER routes — future Token implementation. Actions exist but
      # contain no logic yet (see Companies::TopUpsController).
      resources :top_ups, only: %i[new] do
        collection do
          post :mock_qr_gateway
          post :mock_redirect_gateway
        end
      end

      resource :usage, only: :show, controller: :usage do
        post :enable_logging
        post :disable_logging
      end
      resource :billing, only: :show, controller: :billing

      post "order_processing/v1/checkout", to: "order_processing/v1#checkout"
      post "order_processing/v1/pay", to: "order_processing/v1#pay"
      post "order_processing/v1/pay_cancel", to: "order_processing/v1#pay_cancel"
    end
  end

  # Webhooks — payment API callbacks (placeholder for future Token implementation)
  namespace :webhooks do
    namespace :payments do
      post "mock_qr_gateway",       to: "mock_qr_gateway#create"
      post "mock_redirect_gateway", to: "mock_redirect_gateway#create"
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

  # OmniAuth routes
  get "/auth/:provider/callback", to: "sessions#create_from_omniauth"
  get "/auth/failure", to: "sessions#auth_failure"
  # ----------------------------------------------------------------------------------------------------
  # DEFAULTS
  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get "sign_up", to: "registrations#new"
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
