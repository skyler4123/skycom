json.extract! event_group, :id, :company_group_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url event_group_url(event_group, format: :json)
