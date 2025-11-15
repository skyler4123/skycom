json.extract! company, :id, :user_id, :parent_company_id, :name, :description, :status, :ownership_type, :business_type, :registration_number, :vat_id, :address_line_1, :city, :postal_code, :country, :email, :phone_number, :website, :employee_count, :fiscal_year_end_month, :discarded_at, :created_at, :updated_at
json.url company_url(company, format: :json)
