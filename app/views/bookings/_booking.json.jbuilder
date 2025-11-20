json.extract! booking, :id, :company_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :name, :description, :code, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url booking_url(booking, format: :json)
