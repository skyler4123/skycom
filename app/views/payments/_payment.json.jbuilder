json.extract! payment, :id, :invoice_id, :name, :description, :currency, :exchange_rate, :amount, :payment_method, :gateway_details, :status, :business_type, :discarded_at, :created_at, :updated_at
json.url payment_url(payment, format: :json)
