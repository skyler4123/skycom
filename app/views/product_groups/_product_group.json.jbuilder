json.extract! product_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url product_group_url(product_group, format: :json)
