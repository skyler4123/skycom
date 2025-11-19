json.extract! product, :id, :company_id, :product_brand_id, :name, :description, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url product_url(product, format: :json)
