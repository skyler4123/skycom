json.extract! booking_period, :id, :booking_resource_id, :period_id, :lifecycle_status, :workflow_status, :business_type, :created_at, :updated_at
json.url booking_period_url(booking_period, format: :json)
