# frozen_string_literal: true

module Billing
  class InvoiceService
    def self.call(company, calculator_result, period_start: nil, period_end: nil)
      new(company, calculator_result, period_start: period_start, period_end: period_end).call
    end

    def initialize(company, calculator_result, period_start: nil, period_end: nil)
      @company = company
      @calculator_result = calculator_result
      @period_start = period_start || 1.month.ago.beginning_of_month
      @period_end = period_end || 1.month.ago.end_of_month
    end

    def call
      contract = company.active_billing_contract
      return nil unless contract

      BillingInvoice.create!(
        company: company,
        billing_contract: contract,
        price_cents: calculator_result.total_cents,
        price_currency: "USD",
        period_start: period_start,
        period_end: period_end,
        payment_status: :unpaid,
        lifecycle_status: :final
      )
    end

    private

    attr_reader :company, :calculator_result, :period_start, :period_end
  end
end
