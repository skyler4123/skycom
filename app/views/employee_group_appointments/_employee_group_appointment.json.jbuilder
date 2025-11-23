json.extract! employee_group_appointment, :id, :employee_group_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :code, :created_at, :updated_at
json.url employee_group_appointment_url(employee_group_appointment, format: :json)
