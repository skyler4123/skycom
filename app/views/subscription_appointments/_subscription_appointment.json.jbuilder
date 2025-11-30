json.extract! subscription_appointment, :id, :subscription_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url subscription_appointment_url(subscription_appointment, format: :json)
