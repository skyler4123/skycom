json.extract! assessment, :id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url assessment_url(assessment, format: :json)
