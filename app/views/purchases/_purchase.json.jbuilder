json.extract! purchase, :id, :branch_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url purchase_url(purchase, format: :json)
