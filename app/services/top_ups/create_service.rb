# frozen_string_literal: true

# Creates the credit purchase chain for a top-up (CompanyOrder →
# CompanyInvoice → CompanyTransaction pending) and initiates the gateway
# interaction. The chain is created in one transaction; the gateway's
# webhook later completes the transaction, which credits the wallet.
module TopUps
  class Error < StandardError; end

  class CreateService
    Result = Struct.new(:gateway_type, :qr_string, :redirect_url, keyword_init: true)

    def initialize(company:, money_amount_cents:, billing_payment_method:, redirect_url: nil)
      @company = company
      @money_amount_cents = money_amount_cents.to_i
      @billing_payment_method = billing_payment_method
      @redirect_url = redirect_url
    end

    def call
      raise Error, "Amount must be positive" unless @money_amount_cents.positive?

      credit_amount = CREDIT_RATES[@company.country.to_sym]&.fetch(@money_amount_cents, nil)
      raise Error, "Unsupported top-up amount" unless credit_amount

      ActiveRecord::Base.transaction do
        order = CompanyOrder.create!(
          company: @company, user: @company.user,
          money_amount_cents: @money_amount_cents, credit_amount: credit_amount,
          currency: @company.currency
        )
        invoice = CompanyInvoice.create!(
          company: @company, company_order: order,
          money_amount_cents: @money_amount_cents, credit_amount: credit_amount,
          currency: @company.currency
        )
        txn = CompanyTransaction.create!(
          company: @company, company_invoice: invoice,
          billing_payment_method: @billing_payment_method,
          transaction_type: :payment, money_amount_cents: @money_amount_cents,
          currency: @company.currency, status: :pending,
          gateway_reference: "TOPUP_#{SecureRandom.hex(16)}",
          gateway_payload: {}
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
