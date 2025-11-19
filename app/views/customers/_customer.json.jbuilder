json.extract! customer, :id, :company_id, :name, :description, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url customer_url(customer, format: :json)
