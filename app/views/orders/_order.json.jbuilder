json.extract! order, :id, :company_id, :customer_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :currency, :duration, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url order_url(order, format: :json)
