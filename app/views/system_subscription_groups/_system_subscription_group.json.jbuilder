json.extract! system_subscription_group, :id, :system_subscription_plan_id, :company_id, :branch_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at, :created_at, :updated_at
json.url system_subscription_group_url(system_subscription_group, format: :json)
