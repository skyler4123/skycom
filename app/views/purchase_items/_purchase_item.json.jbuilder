json.extract! purchase_item, :id, :purchase_id, :name, :description, :code, :sku, :barcode, :upc, :ean, :manufacturer_code, :serial_number, :batch_number, :expiration_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url purchase_item_url(purchase_item, format: :json)
