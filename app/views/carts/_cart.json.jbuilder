json.extract! cart, :id, :company_id, :cart_group_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url cart_url(cart, format: :json)
