json.extract! subscription_group, :id, :price_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at, :created_at, :updated_at
json.url subscription_group_url(subscription_group, format: :json)
