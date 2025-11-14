json.extract! tag_appointment, :id, :tag_id, :appoint_to_id, :appoint_to_type, :value, :description, :created_at, :updated_at
json.url tag_appointment_url(tag_appointment, format: :json)
