# frozen_string_literal: true

# Payment API webhook called by the Mock API server when a hosted-redirect
# payment completes. Completing the CompanyTransaction fires the credit chain
# (invoice paid → order completed → wallet credited) — this controller never
# touches balances directly.
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

        txn = CompanyTransaction.find_by(gateway_reference: authorized_token)
        unless txn
          return render json: { errors: [ "Transaction not found" ] }, status: :not_found
        end

        if txn.completed?
          return render json: { status: "already_completed" }, status: :ok
        end

        unless settlement_amount == txn.money_amount_cents
          return render json: { errors: [ "Amount mismatch" ] }, status: :unprocessable_content
        end

        txn.update!(status: :completed)

        WEBSOCKET.publish_event(
          channel: WEBSOCKET.company_channel(txn.company_id),
          event_key: :top_up_completed,
          data: {
            amount_cents: settlement_amount,
            transaction_id: txn.id
          }
        )

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
