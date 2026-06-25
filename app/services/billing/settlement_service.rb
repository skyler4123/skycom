# frozen_string_literal: true

# Deducts invoice amount from company wallet: promo_balance first, then main_balance.
# If both are exhausted, trips the circuit breaker (suspends the company).
#
# Called by MonthlyBillingJob as step 3 of the billing pipeline.
#
#   SettlementService.call(invoice)
#   # → promo_balance 500 → 0, main_balance 1000 → 700
#   # → invoice.payment_status → :paid
#
# Deduction algorithm:
#   1. Deduct from promo_balance (promotional credits expire first)
#   2. Deduct remainder from main_balance (customer's real money)
#   3. If still remaining → mark_past_due! + invoice marked :overdue
#
# Every balance change is recorded as a WalletTransaction with before/after snapshots.
#
# Balance mutations use update_columns (bypasses callbacks) to prevent the
# CircuitBreakerConcern's attempt_settle_outstanding from re-entering settlement
# via company.update! during deduct_from_promo/deduct_from_main.
#
module Billing
  class SettlementService
    def self.call(invoice)
      new(invoice).call
    end

    # Attempts to settle all unpaid invoices for a company, oldest first.
    # Stops when wallet is exhausted. Returns the number of invoices fully paid.
    #
    # Re-entrance guard: if this company is already being settled (e.g. from an
    # attempt_settle_outstanding callback), returns 0 immediately.
    def self.settle_all(company)
      settling = (Thread.current[:__settling_companies] ||= Set.new)
      return { paid_count: 0, remaining_cents: 0 } unless settling.add?(company.id)

      unpaid = company.billing_invoices
                      .where(payment_status: %i[unpaid overdue])
                      .order(:created_at)

      paid_count = 0
      unpaid.each do |invoice|
        call(invoice)
        paid_count += 1 if invoice.reload.paid?
      end

      remaining_cents = company.billing_invoices
                               .where(payment_status: %i[unpaid overdue])
                               .sum(:price_cents)

      { paid_count: paid_count, remaining_cents: remaining_cents }
    ensure
      Thread.current[:__settling_companies]&.delete(company&.id)
    end

    def initialize(invoice)
      @invoice = invoice
      @company = invoice.company
    end

    def call
      total = invoice.price_cents
      return mark_paid if total.zero?

      # Invoice-level re-entry guard (safety net)
      guard_set = (Thread.current[:__settling_invoice_ids] ||= Set.new)
      return if guard_set.include?(invoice.id)
      guard_set.add(invoice.id)

      company.with_lock do
        remaining = deduct_from_promo(total)
        remaining = deduct_from_main(remaining)

        # Reload to get fresh balance values after update_columns
        company.reload

        if remaining > 0
          handle_shortfall(remaining)
        else
          mark_paid
        end
      end
    ensure
      Thread.current[:__settling_invoice_ids]&.delete(invoice&.id)
    end

    private

    attr_reader :invoice, :company

    def deduct_from_promo(amount)
      promo_before = company.promo_balance_cents

      if promo_before >= amount
        promo_after = promo_before - amount
        company.update_columns(promo_balance_cents: promo_after)
        record_transaction(:deduction, amount,
                           promo_before, promo_after,
                           company.main_balance_cents, company.main_balance_cents)
        return 0
      end

      company.update_columns(promo_balance_cents: 0)
      record_transaction(:deduction, promo_before,
                         promo_before, 0,
                         company.main_balance_cents, company.main_balance_cents) if promo_before > 0
      amount - promo_before
    end

    def deduct_from_main(amount)
      return 0 if amount.zero?

      main_before = company.main_balance_cents

      if main_before >= amount
        main_after = main_before - amount
        company.update_columns(main_balance_cents: main_after)
        record_transaction(:deduction, amount,
                           main_before, main_after,
                           company.promo_balance_cents, company.promo_balance_cents)
        return 0
      end

      company.update_columns(main_balance_cents: 0)
      record_transaction(:deduction, main_before,
                         main_before, 0,
                         company.promo_balance_cents, company.promo_balance_cents) if main_before > 0
      amount - main_before
    end

    def handle_shortfall(remaining)
      company.mark_past_due!
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
