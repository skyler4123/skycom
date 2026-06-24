# frozen_string_literal: true

module Billing
  class SettlementService
    def self.call(invoice)
      new(invoice).call
    end

    def initialize(invoice)
      @invoice = invoice
      @company = invoice.company
    end

    def call
      total = invoice.price_cents
      return mark_paid if total.zero?

      company.with_lock do
        remaining = deduct_from_promo(total)
        remaining = deduct_from_main(remaining)

        if remaining > 0
          handle_shortfall(remaining)
        else
          mark_paid
        end
      end
    end

    private

    attr_reader :invoice, :company

    def deduct_from_promo(amount)
      promo_before = company.promo_balance_cents

      if promo_before >= amount
        company.update!(promo_balance_cents: promo_before - amount)
        record_transaction(:deduction, amount,
                           promo_before, promo_before - amount,
                           company.main_balance_cents, company.main_balance_cents)
        return 0
      end

      company.update!(promo_balance_cents: 0)
      record_transaction(:deduction, promo_before, promo_before, 0,
                         company.main_balance_cents, company.main_balance_cents) if promo_before > 0
      amount - promo_before
    end

    def deduct_from_main(amount)
      return 0 if amount.zero?

      main_before = company.main_balance_cents

      if main_before >= amount
        company.update!(main_balance_cents: main_before - amount)
        record_transaction(:deduction, amount,
                           main_before, main_before - amount,
                           company.promo_balance_cents, company.promo_balance_cents)
        return 0
      end

      company.update!(main_balance_cents: 0)
      record_transaction(:deduction, main_before, main_before, 0,
                         company.promo_balance_cents, company.promo_balance_cents) if main_before > 0
      amount - main_before
    end

    def handle_shortfall(remaining)
      company.circuit_breaker_trip!
      invoice.update!(payment_status: :overdue)

      record_transaction(:deduction, 0,
                         company.main_balance_cents, company.main_balance_cents,
                         company.promo_balance_cents, company.promo_balance_cents)
    end

    def mark_paid
      invoice.update!(payment_status: :paid)
    end

    def record_transaction(type, amount,
                           before_main, after_main,
                           before_promo, after_promo)
      WalletTransaction.create!(
        company: company,
        billing_invoice: invoice,
        transaction_type: type,
        amount_cents: amount,
        currency: "USD",
        balance_before_cents: before_main,
        balance_after_cents: after_main,
        promo_balance_before_cents: before_promo,
        promo_balance_after_cents: after_promo,
        description: "Monthly billing invoice #{invoice.invoice_number}"
      )
    end
  end
end
