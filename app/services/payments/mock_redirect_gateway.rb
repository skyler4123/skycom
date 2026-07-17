# app/services/payments/mock_redirect_gateway.rb
module Payments
  class MockRedirectGateway
    def initialize(amount_cents:, invoice_id:, memo:, redirect_url: nil, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @redirect_url = redirect_url
      @gateway_url = GATEWAY_CONFIGS[:mock_redirect_gateway][:gateway_url]
      @secret_key = GATEWAY_CONFIGS[:mock_redirect_gateway][:secret_key]
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
          return_url: @redirect_url
        }
      end

      if response.success?
        {
          success: true,
          gateway_reference: "MOCK_SESS_#{Time.current.to_i}",
          gateway_payload: {
            redirect_url: response.body["redirect_url"]
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
