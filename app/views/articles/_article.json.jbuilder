json.extract! article, :id, :article_group_id, :company_group_id, :company_id, :title, :content, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url article_url(article, format: :json)
