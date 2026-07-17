# app/services/payments/mock_qr_gateway.rb
module Payments
  class MockQrGateway
    def initialize(amount_cents:, invoice_id:, transaction_token:, memo:, gateway_url:, secret_key:, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @transaction_token = transaction_token
      @memo = memo
      @gateway_url = gateway_url
      @secret_key = secret_key
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
          transaction_token: @transaction_token, # Send unique transaction tracking token
          memo: @memo
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
