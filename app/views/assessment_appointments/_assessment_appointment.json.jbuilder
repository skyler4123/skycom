json.extract! assessment_appointment, :id, :assessment_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url assessment_appointment_url(assessment_appointment, format: :json)
