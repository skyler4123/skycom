json.extract! employee_group, :id, :branch_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url employee_group_url(employee_group, format: :json)
