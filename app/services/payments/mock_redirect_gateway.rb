# app/services/payments/mock_redirect_gateway.rb
module Payments
  class MockRedirectGateway
    def initialize(amount_cents:, invoice_id:, memo:, transaction_token: nil, redirect_url: nil, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @transaction_token = transaction_token
      @redirect_url = redirect_url
      @gateway_url = GATEWAY_CONFIGS[:mock_redirect_gateway][:gateway_url]
      @secret_key = GATEWAY_CONFIGS[:mock_redirect_gateway][:secret_key]
      @webhook_url = GATEWAY_CONFIGS[:mock_redirect_gateway][:webhook_url]
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
          amount_cents: @amount_cents,
          invoice_uuid: @invoice_id,
          txn_channel_token: @transaction_token,
          redirect_url: @redirect_url,
          callback_webhook: @webhook_url
        }
      end

      if response.success?
        {
          success: true,
          gateway_reference: "MOCK_SESS_#{Time.current.to_i}",
          gateway_payload: {
            redirect_url: response.body["checkout_url"]
          }
        }
      else
        { success: false, error: response.body["error"] || "Redirect session generation failed" }
      end
    rescue Faraday::Error => e
      { success: false, error: "Network failure: #{e.message}" }
    end
  end
end
