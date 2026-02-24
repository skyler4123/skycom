json.extract! invoice, :id, :order_id, :name, :description, :code, :currency_code, :duration, :number, :total, :due_date, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url invoice_url(invoice, format: :json)
