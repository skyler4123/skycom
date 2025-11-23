json.extract! product, :id, :company_id, :brand_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url product_url(product, format: :json)
