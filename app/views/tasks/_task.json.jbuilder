json.extract! task, :id, :company_id, :task_group_id, :name, :description, :code, :currency, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url task_url(task, format: :json)
