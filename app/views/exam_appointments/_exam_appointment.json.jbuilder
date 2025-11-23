json.extract! exam_appointment, :id, :exam_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url exam_appointment_url(exam_appointment, format: :json)
