# frozen_string_literal: true

# Creates monthly invoices for ALL non-disabled companies.
# Runs on the 1st of each month at 00:00 (configured in config/recurring.yml).
#
# Pipeline per company:
#   1. CalculatorService.call(company)         -> Result (total_cents + breakdown)
#   2. InvoiceService.call(company, result)     -> BillingInvoice (unpaid)
#   3. If company now has unpaid invoices      -> mark_past_due!
#
# No auto-settlement -- payment happens voluntarily via BillingController
# or attempt_settle_outstanding on balance change.
#
# disabled: skipped entirely (terminal state)
# Skips companies with zero total (nothing to bill).
# Isolated per company -- one failure doesn't affect others.
#
module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.where.not(lifecycle_status: :disabled).find_each(batch_size: 50) do |company|
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

      company.mark_past_due! if company.billing_invoices.where(payment_status: %i[unpaid overdue]).exists?
    end
  end
end
