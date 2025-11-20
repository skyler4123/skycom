json.extract! payment_method_appointment, :id, :payment_method_id, :company_id, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url payment_method_appointment_url(payment_method_appointment, format: :json)
