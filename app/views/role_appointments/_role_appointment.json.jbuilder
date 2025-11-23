json.extract! role_appointment, :id, :role_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url role_appointment_url(role_appointment, format: :json)
