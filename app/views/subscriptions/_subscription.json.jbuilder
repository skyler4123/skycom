json.extract! subscription, :id, :subscription_group_id, :price_id, :period_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :country_code, :auto_renew, :discarded_at, :created_at, :updated_at
json.url subscription_url(subscription, format: :json)
