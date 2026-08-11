# frozen_string_literal: true

# PLACEHOLDER CONTROLLER — future Token implementation.
#
# This is the payment API webhook that the bank gateway calls when a QR
# payment completes. The API contract is preserved (signature check, param
# validation, idempotency, response shapes) but the money movement logic is
# a placeholder for the future Token system.
module Webhooks
  module Payments
    class MockQrGatewayController < ActionController::Base
      skip_before_action :verify_authenticity_token
      before_action :ensure_not_production

      def create
        received_sig = request.headers["X-Skycom-Bank-Signature"]
        unless received_sig == WEBHOOK_BANK_PAYMENT_SECRET
          return render json: { errors: [ "Invalid signature" ] }, status: :unauthorized
        end

        data = params[:data] || params
        transaction_token = data[:transaction_token]
        amount = data[:amount].to_i

        unless transaction_token.present? && amount.positive?
          return render json: { errors: [ "Missing transaction_token or amount" ] }, status: :unprocessable_content
        end

        # TODO: Token implementation — on confirmed QR payment:
        #   1. Look up the pending top-up by gateway_reference (transaction_token)
        #   2. Credit the company's token balance (amount → token conversion)
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
