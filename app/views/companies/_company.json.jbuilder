json.extract! company, :id, :user_id, :parent_company_id, :name, :description, :created_at, :updated_at
json.url company_url(company, format: :json)
