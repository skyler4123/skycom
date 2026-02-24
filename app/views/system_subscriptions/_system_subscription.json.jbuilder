json.extract! system_subscription, :id, :system_subscription_plan_id, :subscription_group_id, :company_group_id, :company_id, :price_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at, :created_at, :updated_at
json.url system_subscription_url(system_subscription, format: :json)
