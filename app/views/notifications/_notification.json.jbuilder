json.extract! notification, :id, :notification_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url notification_url(notification, format: :json)
