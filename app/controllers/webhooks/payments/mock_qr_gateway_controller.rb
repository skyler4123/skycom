# frozen_string_literal: true

# Payment API webhook called by the Mock API server when a QR payment
# completes. Completing the CompanyTransaction fires the credit chain
# (invoice paid → order completed → wallet credited) — this controller never
# touches balances directly.
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

        txn = CompanyTransaction.find_by(gateway_reference: transaction_token)
        unless txn
          return render json: { errors: [ "Transaction not found" ] }, status: :not_found
        end

        if txn.completed?
          return render json: { status: "already_completed" }, status: :ok
        end

        unless amount == txn.money_amount_cents
          return render json: { errors: [ "Amount mismatch" ] }, status: :unprocessable_content
        end

        txn.update!(status: :completed)

        WEBSOCKET.publish_event(
          channel: WEBSOCKET.company_channel(txn.company_id),
          event_key: :top_up_completed,
          data: {
            amount_cents: amount,
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
