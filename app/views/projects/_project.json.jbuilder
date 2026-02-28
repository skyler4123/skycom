json.extract! project, :id, :branch_id, :project_group_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url project_url(project, format: :json)
