# frozen_string_literal: true

# Gateway strategy for QR bank-transfer payments (dev mock).
# Calls the Mock API server's QR generator; the mock later fires a webhook to
# WEBHOOK_URL marking the payment completed. Contract: #call returns
# { success:, gateway_reference:, gateway_payload: } or { success: false, error: }.
module Payments
  class MockQrGateway
    GATEWAY_URL = ENV["MOCK_QR_GATEWAY_URL"] ||
      Rails.application.credentials.mock_qr_gateway_url ||
      "http://localhost:4000/api/v1/bank/qr-generate"
    WEBHOOK_URL = ENV["MOCK_QR_WEBHOOK_URL"] ||
      Rails.application.credentials.mock_qr_webhook_url ||
      "http://192.168.0.100:3000/webhooks/payments/mock_qr_gateway"

    def initialize(amount_cents:, invoice_id:, memo:, transaction_token:,
                   merchant_number: nil, merchant_name: nil, merchant_id: nil, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @transaction_token = transaction_token
      @merchant_number = merchant_number
      @merchant_name = merchant_name
      @merchant_id = merchant_id
    end

    def call
      conn = Faraday.new(url: GATEWAY_URL) do |f|
        f.request :json
        f.response :json
        f.options.timeout = 5
      end

      response = conn.post do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          amount: @amount_cents,
          invoice_id: @invoice_id,
          memo: @memo,
          transaction_token: @transaction_token,
          merchant_number: @merchant_number,
          merchant_name: @merchant_name,
          merchant_id: @merchant_id,
          webhook_url: WEBHOOK_URL
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
