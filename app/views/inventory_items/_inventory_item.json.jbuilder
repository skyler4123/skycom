json.extract! inventory_item, :id, :inventory_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url inventory_item_url(inventory_item, format: :json)
