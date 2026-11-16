# frozen_string_literal: true

# Gateway strategy for hosted-redirect payments (dev mock).
# Calls the Mock API server to create a checkout session; the mock's hosted
# page redirects the user back to redirect_url and fires a webhook to
# MOCK_REDIRECT_WEBHOOK_URL marking the payment completed. Contract: #call returns
# { success:, gateway_reference:, gateway_payload: } or { success: false, error: }.
module Payments
  class MockRedirectGateway
    def initialize(amount_cents:, invoice_id:, memo:, transaction_token:, redirect_url:, **_args)
      @amount_cents = amount_cents
      @invoice_id = invoice_id
      @memo = memo
      @transaction_token = transaction_token
      @redirect_url = redirect_url
    end

    def call
      conn = Faraday.new(url: MOCK_REDIRECT_GATEWAY_URL) do |f|
        f.request :json
        f.response :json
        f.options.timeout = 5
      end

      response = conn.post do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          amount_cents: @amount_cents,
          invoice_uuid: @invoice_id,
          txn_channel_token: @transaction_token,
          redirect_url: @redirect_url,
          callback_webhook: MOCK_REDIRECT_WEBHOOK_URL
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
