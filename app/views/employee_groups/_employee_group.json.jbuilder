json.extract! employee_group, :id, :company_id, :name, :description, :created_at, :updated_at
json.url employee_group_url(employee_group, format: :json)
