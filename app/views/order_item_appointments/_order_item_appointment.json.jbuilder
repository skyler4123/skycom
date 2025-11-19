json.extract! order_item_appointment, :id, :order_id, :appoint_to_id, :appoint_to_type, :unit_price, :quantity, :total_price, :name, :description, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url order_item_appointment_url(order_item_appointment, format: :json)
