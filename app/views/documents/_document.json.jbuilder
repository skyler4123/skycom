json.extract! document, :id, :document_group_id, :company_group_id, :company_id, :title, :content, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url document_url(document, format: :json)
