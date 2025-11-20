json.extract! task_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url task_group_url(task_group, format: :json)
