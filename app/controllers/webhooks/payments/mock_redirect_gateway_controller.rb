# frozen_string_literal: true

# PLACEHOLDER CONTROLLER — future Token implementation.
#
# This is the payment API webhook that the bank gateway calls when a hosted
# redirect checkout completes. The API contract is preserved (signature
# check, param validation, idempotency, response shapes) but the money
# movement logic is a placeholder for the future Token system.
module Webhooks
  module Payments
    class MockRedirectGatewayController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :ensure_not_production

      def create
        received_sig = request.headers["X-Skycom-RedirectBank-Signature"]
        unless received_sig == WEBHOOK_REDIRECT_PAYMENT_SECRET
          return render json: { errors: [ "Invalid signature" ] }, status: :unauthorized
        end

        data = params
        authorized_token = data[:authorized_token]
        settlement_amount = data[:settlement_amount].to_i

        unless authorized_token.present? && settlement_amount.positive?
          return render json: { errors: [ "Missing authorized_token or settlement_amount" ] }, status: :unprocessable_content
        end

        # TODO: Token implementation — on confirmed redirect payment:
        #   1. Look up the pending top-up by gateway_reference (authorized_token)
        #   2. Credit the company's token balance (settlement_amount → token conversion)
        #   3. Publish the top_up_completed websocket event to the company channel
        # Previously this credited billing_wallet.main_balance_cents; that model
        # was removed with the billing system.
        render json: { status: "completed" }
      end

      private

      def ensure_not_production
        return unless Rails.env.production?
        render json: { errors: [ "Mock gateway not available in production" ] }, status: :not_found
      end
    end
  end
end
