# frozen_string_literal: true

# Payment API webhook called by the Mock API server when a QR payment
# completes. Resolves the token against the B2B credit chain
# (CompanyTransaction — wallet top-ups) first, then against POS sales
# Transactions. Completion side-effects live in the models/services — this
# controller never touches balances directly.
# Serves Stimulus: Companies_TopUps_NewController (top_up_completed),
#                  Companies_Pages_RetailCashierController (pos_payment_completed)
# Subscribed via: window.WEBSOCKET.subscribe(companyChannel, eventKey, (data) => ...)
# Docs: docs/WEBSOCKET.md, docs/ORDER_PROCESSING_V1.md
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

        if (billing_txn = CompanyTransaction.find_by(gateway_reference: transaction_token))
          return complete_billing_transaction(billing_txn, amount)
        end

        if (pos_txn = Transaction.find_by(gateway_reference: transaction_token))
          return complete_pos_transaction(pos_txn, amount)
        end

        render json: { errors: [ "Transaction not found" ] }, status: :not_found
      end

      private

      def complete_billing_transaction(txn, amount)
        return render json: { status: "already_completed" }, status: :ok if txn.completed?

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

      def complete_pos_transaction(txn, amount)
        unless amount == txn.price_cents
          return render json: { errors: [ "Amount mismatch" ] }, status: :unprocessable_content
        end

        unless txn.pending?
          return render json: { status: txn.status }, status: :ok
        end

        OrderProcessingV1::CompletePaymentService.call(transaction: txn)

        WEBSOCKET.publish_event(
          channel: WEBSOCKET.company_channel(txn.company_id),
          event_key: :pos_payment_completed,
          data: {
            id: txn.id,
            transaction_token: txn.gateway_reference,
            order_id: txn.invoice.order_id,
            amount_cents: amount
          }
        )

        render json: { status: "completed" }
      end

      def ensure_not_production
        return unless Rails.env.production?
        render json: { errors: [ "Mock gateway not available in production" ] }, status: :not_found
      end
    end
  end
end
