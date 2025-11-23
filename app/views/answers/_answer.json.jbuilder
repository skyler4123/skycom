json.extract! answer, :id, :question_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url answer_url(answer, format: :json)
