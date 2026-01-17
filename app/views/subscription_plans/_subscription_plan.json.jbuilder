json.extract! subscription_plan, :id, :company_group_id, :company_id, :price_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at, :created_at, :updated_at
json.url subscription_plan_url(subscription_plan, format: :json)
