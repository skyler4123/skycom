# frozen_string_literal: true

# Orchestrates the monthly billing pipeline for every active company.
# Runs on the 1st of each month at 00:00 (configured in config/recurring.yml).
#
# Pipeline per company:
#   1. CalculatorService.call(company)         → Result (total_cents + breakdown)
#   2. InvoiceService.call(company, result)     → BillingInvoice
#   3. SettlementService.call(invoice)          → deducts wallet, or trips breaker
#
# Skips companies with zero total (nothing to bill).
# Isolated per company — one failure doesn't affect others.
#
module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.lifecycle_status_active.or(Company.lifecycle_status_past_due).find_each(batch_size: 50) do |company|
        process_company(company)
      rescue StandardError => e
        Rails.logger.error("MonthlyBillingJob: Failed for company #{company.id}: #{e.message}")
      end
    end

    private

    def process_company(company)
      result = CalculatorService.call(company)
      return if result.total_cents.zero? && result.breakdown&.total_cents.to_i.zero?

      invoice = InvoiceService.call(company, result)
      return unless invoice

      SettlementService.call(invoice)
    end
  end
end
