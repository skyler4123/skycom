# frozen_string_literal: true

module TopUps
  class Error < StandardError; end

  class CreateService
    Result = Struct.new(:gateway_type, :qr_string, :redirect_url, keyword_init: true)

    def initialize(company:, amount_cents:, billing_payment_method:, redirect_url: nil)
      @company = company
      @amount_cents = amount_cents.to_i
      @billing_payment_method = billing_payment_method
      @redirect_url = redirect_url
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

        Payments::InitiateService.new(transaction: txn, redirect_url: @redirect_url).call

        txn.reload

        payload = txn.gateway_payload || {}

        if payload["redirect_url"].present?
          Result.new(gateway_type: "redirect", redirect_url: payload["redirect_url"])
        elsif payload["qr_string"].present?
          Result.new(gateway_type: "qr", qr_string: payload["qr_string"])
        else
          Result.new(gateway_type: "unknown")
        end
      end
    end
  end
end
