json.extract! employee, :id, :user_id, :company_id, :name, :description, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url employee_url(employee, format: :json)
