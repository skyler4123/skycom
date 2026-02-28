json.extract! booking_resource, :id, :company_id, :branch_id, :booking_resourceable_id, :booking_resourceable_type, :name, :description, :lifecycle_status, :workflow_status, :business_type, :discarded_at, :created_at, :updated_at
json.url booking_resource_url(booking_resource, format: :json)
