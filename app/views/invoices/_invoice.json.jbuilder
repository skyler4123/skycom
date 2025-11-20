json.extract! invoice, :id, :order_id, :name, :description, :currency, :number, :total, :due_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url invoice_url(invoice, format: :json)
