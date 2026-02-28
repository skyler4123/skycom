json.extract! department, :id, :company_id, :name, :description, :code, :lifecycle_status, :workflow_status, :business_type, :discarded_at, :created_at, :updated_at
json.url department_url(department, format: :json)
