json.extract! article_group, :id, :company_group_id, :company_id, :title, :content, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url article_group_url(article_group, format: :json)
