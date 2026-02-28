json.extract! booking, :id, :company_id, :branch_id, :booking_resource_id, :price_id, :appoint_from_id, :appoint_from_type, :appoint_to_id, :appoint_to_type, :appoint_for_id, :appoint_for_type, :appoint_by_id, :appoint_by_type, :name, :description, :price_id, :lifecycle_status, :workflow_status, :business_type, :discarded_at, :created_at, :updated_at
json.url booking_url(booking, format: :json)
