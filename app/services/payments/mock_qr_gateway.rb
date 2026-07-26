# app/services/payments/mock_qr_gateway.rb
module Payments
  class MockQrGateway
    GATEWAY_URL  = ENV["MOCK_QR_GATEWAY_URL"]  || Rails.application.credentials.mock_qr_gateway_url  || "http://localhost:4000/api/v1/bank/qr-generate"
    SECRET_KEY   = ENV["MOCK_QR_SECRET_KEY"]    || Rails.application.credentials.mock_qr_secret_key    || "local_secure_dev_secret"
    WEBHOOK_URL  = ENV["MOCK_QR_WEBHOOK_URL"]   || Rails.application.credentials.mock_qr_webhook_url   || "http://192.168.0.100:3000/webhooks/payments/mock_qr_gateway"

    def initialize(amount_cents:, invoice_id:, memo:, transaction_token: nil, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @transaction_token = transaction_token
      @gateway_url = GATEWAY_URL
      @secret_key = SECRET_KEY
      @webhook_url = WEBHOOK_URL
    end

    def call
      conn = Faraday.new(url: @gateway_url) do |f|
        f.request :json
        f.response :json
        f.options.timeout = 5
      end

      response = conn.post do |req|
        req.headers["Content-Type"] = "application/json"
        req.headers["Authorization"] = "Bearer #{@secret_key}"
        req.body = {
          amount: @amount_cents,
          invoice_id: @invoice_id,
          memo: @memo,
          transaction_token: @transaction_token,
          webhook_url: @webhook_url
        }
      end

      if response.success?
        {
          success: true,
          gateway_reference: "MOCK_QR_#{Time.current.to_i}",
          gateway_payload: {
            qr_string: response.body["qr_string"]
          }
        }
      else
        { success: false, error: response.body["error"] || "QR generation failed" }
      end
    rescue Faraday::Error => e
      { success: false, error: "Network failure: #{e.message}" }
    end
  end
end
