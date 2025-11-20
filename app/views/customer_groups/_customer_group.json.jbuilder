json.extract! customer_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url customer_group_url(customer_group, format: :json)
