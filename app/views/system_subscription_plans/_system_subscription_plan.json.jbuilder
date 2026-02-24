json.extract! system_subscription_plan, :id, :price_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :discarded_at, :created_at, :updated_at
json.url system_subscription_plan_url(system_subscription_plan, format: :json)
