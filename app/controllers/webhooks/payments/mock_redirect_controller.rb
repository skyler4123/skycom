# frozen_string_literal: true

module Webhooks
  module Payments
    class MockRedirectController < ActionController::Base
      skip_before_action :verify_authenticity_token

      def create
        received_sig = request.headers["X-Skycom-RedirectBank-Signature"]
        unless received_sig == WEBHOOK_REDIRECT_PAYMENT_SECRET
          return render json: { error: "Invalid signature" }, status: :unauthorized
        end

        data = params
        authorized_token = data[:authorized_token]
        settlement_amount = data[:settlement_amount].to_i

        unless authorized_token.present? && settlement_amount.positive?
          return render json: { error: "Missing authorized_token or settlement_amount" }, status: :unprocessable_content
        end

        txn = BillingTransaction.find_by(gateway_reference: authorized_token)
        unless txn
          return render json: { error: "Transaction not found" }, status: :not_found
        end

        if txn.status_completed?
          return render json: { status: "already_completed" }, status: :ok
        end

        company = txn.company

        ActiveRecord::Base.transaction do
          wallet = company.billing_wallet.lock!
          new_main = wallet.main_balance_cents + settlement_amount
          wallet.update!(main_balance_cents: new_main)

          txn.update!(
            status: :completed,
            gateway_reference: data[:reference_code] || txn.gateway_reference,
            balance_after_cents: new_main
          )
        end

        WEBSOCKET.publish_event(
          channel: WEBSOCKET.company_channel(company&.id),
          event_key: :top_up_completed,
          data: {
            amount_cents: settlement_amount,
            transaction_id: txn.id
          }
        )

        render json: { status: "completed" }
      end
    end
  end
end
