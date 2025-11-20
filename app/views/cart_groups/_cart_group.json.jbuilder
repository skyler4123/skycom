json.extract! cart_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url cart_group_url(cart_group, format: :json)
