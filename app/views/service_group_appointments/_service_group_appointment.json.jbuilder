json.extract! service_group_appointment, :id, :service_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :duration, :start_at, :business_type, :discarded_at, :created_at, :updated_at
json.url service_group_appointment_url(service_group_appointment, format: :json)
