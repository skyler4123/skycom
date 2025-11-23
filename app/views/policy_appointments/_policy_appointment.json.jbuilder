json.extract! policy_appointment, :id, :policy_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url policy_appointment_url(policy_appointment, format: :json)
