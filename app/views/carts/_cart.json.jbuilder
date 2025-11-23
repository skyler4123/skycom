json.extract! cart, :id, :company_id, :cart_group_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url cart_url(cart, format: :json)
