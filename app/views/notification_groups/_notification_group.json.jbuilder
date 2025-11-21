json.extract! notification_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url notification_group_url(notification_group, format: :json)
