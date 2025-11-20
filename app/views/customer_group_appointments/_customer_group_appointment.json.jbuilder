json.extract! customer_group_appointment, :id, :customer_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url customer_group_appointment_url(customer_group_appointment, format: :json)
