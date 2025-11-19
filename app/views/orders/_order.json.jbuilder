json.extract! order, :id, :company_id, :customer_id, :name, :description, :currency, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url order_url(order, format: :json)
