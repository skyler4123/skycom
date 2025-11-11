json.extract! company, :id, :name, :user_id, :parent_company_id, :created_at, :updated_at
json.url company_url(company, format: :json)
