json.extract! exam_group, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url exam_group_url(exam_group, format: :json)
