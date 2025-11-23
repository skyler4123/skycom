json.extract! service_appointment, :id, :service_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at, :created_at, :updated_at
json.url service_appointment_url(service_appointment, format: :json)
