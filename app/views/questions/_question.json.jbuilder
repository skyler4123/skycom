json.extract! question, :id, :branch_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url question_url(question, format: :json)
