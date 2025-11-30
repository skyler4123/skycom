json.extract! company_group, :id, :user_id, :name, :description, :code, :status, :ownership_type, :business_type, :currency, :registration_number, :vat_id, :address_line_1, :city, :postal_code, :country, :email, :phone_number, :website, :employee_count, :fiscal_year_end_month, :discarded_at, :created_at, :updated_at
json.url company_group_url(company_group, format: :json)
