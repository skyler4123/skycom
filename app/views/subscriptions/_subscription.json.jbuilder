json.extract! subscription, :id, :subscription_group_id, :company_group_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url subscription_url(subscription, format: :json)
