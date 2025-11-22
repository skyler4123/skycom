json.extract! tag_appointment, :id, :tag_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :value, :description, :created_at, :updated_at
json.url tag_appointment_url(tag_appointment, format: :json)
