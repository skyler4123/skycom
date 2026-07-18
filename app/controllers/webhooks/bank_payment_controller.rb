# frozen_string_literal: true

module Webhooks
  class BankPaymentController < ActionController::Base
    skip_before_action :verify_authenticity_token

    def create
      received_sig = request.headers["X-Skycom-Bank-Signature"]
      unless received_sig == WEBHOOK_BANK_PAYMENT_SECRET
        return render json: { error: "Invalid signature" }, status: :unauthorized
      end

      data = params[:data] || params
      transaction_token = data[:transaction_token]
      amount = data[:amount].to_i

      unless transaction_token.present? && amount.positive?
        return render json: { error: "Missing transaction_token or amount" }, status: :unprocessable_content
      end

      txn = BillingTransaction.find_by(gateway_reference: transaction_token)
      unless txn
        return render json: { error: "Transaction not found" }, status: :not_found
      end

      if txn.status_completed?
        return render json: { status: "already_completed" }, status: :ok
      end

      company = txn.company

      ActiveRecord::Base.transaction do
        wallet = company.billing_wallet.lock!
        new_main = wallet.main_balance_cents + amount
        wallet.update!(main_balance_cents: new_main)

        txn.update!(
          status: :completed,
          gateway_reference: data[:transaction_id] || txn.gateway_reference,
          balance_after_cents: new_main
        )
      end

      channel = "company:#{company.id}:top_up"
      Websocket.publish(
        channel: channel,
        data: {
          event: "top_up.completed",
          amount_cents: amount,
          transaction_id: txn.id
        }
      )

      render json: { status: "completed" }
    end
  end
end
