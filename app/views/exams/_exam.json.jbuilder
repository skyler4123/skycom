json.extract! exam, :id, :exam_group_id, :branch_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url exam_url(exam, format: :json)
