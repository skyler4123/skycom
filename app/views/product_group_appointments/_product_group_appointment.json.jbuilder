json.extract! product_group_appointment, :id, :product_group_id, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url product_group_appointment_url(product_group_appointment, format: :json)
