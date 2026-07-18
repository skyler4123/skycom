# frozen_string_literal: true

module TopUps
  class Error < StandardError; end

  class CreateService
    Result = Struct.new(:qr_string, :websocket_url, :websocket_token, :websocket_channel, keyword_init: true)

    def initialize(company:, amount_cents:, billing_payment_method:)
      @company = company
      @amount_cents = amount_cents.to_i
      @billing_payment_method = billing_payment_method
    end

    def call
      raise Error, "Amount must be positive" unless @amount_cents.positive?

      ActiveRecord::Base.transaction do
        wallet = @company.billing_wallet
        raise Error, "No billing wallet found" unless wallet

        gateway_ref = "TOPUP_#{SecureRandom.hex(16)}"

        contract = @company.active_billing_contract
        raise Error, "No active billing contract" unless contract

        invoice = BillingInvoice.create!(
          company: @company,
          billing_contract: contract,
          movement_type: :deposit,
          target_balance: :main_balance,
          created_by: :customer,
          price_cents: @amount_cents,
          payment_status: :unpaid
        )

        promo_before = wallet.promo_balance_cents
        main_before = wallet.main_balance_cents

        txn = BillingTransaction.create!(
          company: @company,
          billing_invoice: invoice,
          billing_payment_method: @billing_payment_method,
          transaction_type: :top_up,
          amount_cents: @amount_cents,
          gateway_reference: gateway_ref,
          gateway_payload: {},
          status: :pending,
          balance_before_cents: main_before,
          balance_after_cents: main_before,
          promo_balance_before_cents: promo_before,
          promo_balance_after_cents: promo_before,
          currency: @company.currency || :usd,
          description: "Wallet top-up of #{@amount_cents} cents via #{@billing_payment_method.name}"
        )

        Payments::InitiateService.new(transaction: txn).call

        txn.reload

        qr_string = txn.gateway_payload&.dig("qr_string") || txn.gateway_payload&.dig(:qr_string)

        channel_name = "company_#{@company.id}_top_up"
        ws_token = Websocket.token(sub: txn.id, channels: [ channel_name ])

        Result.new(
          qr_string: qr_string,
          websocket_url: "ws://localhost:8000/connection/websocket",
          websocket_token: ws_token,
          websocket_channel: channel_name
        )
      end
    end
  end
end
