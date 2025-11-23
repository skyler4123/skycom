json.extract! order_group, :id, :company_id, :customer_id, :name, :description, :code, :currency, :duration, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url order_group_url(order_group, format: :json)
