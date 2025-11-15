json.extract! role_appointment, :id, :role_id, :appoint_to_id, :appoint_to_type, :name, :description, :status, :kind, :discarded_at, :created_at, :updated_at
json.url role_appointment_url(role_appointment, format: :json)
