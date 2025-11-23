json.extract! inventory, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url inventory_url(inventory, format: :json)
