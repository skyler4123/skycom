# frozen_string_literal: true

# Creates monthly invoices for non-disabled, non-suspended companies.
# Runs on the 1st of each month at 00:00 (configured in config/recurring.yml).
#
# Pipeline per company:
#   1. CalculatorService.call(company)         -> Result (total_cents + breakdown)
#   2. InvoiceService.call(company, result)     -> BillingInvoice (unpaid)
#   3. If company now has unpaid invoices      -> flag_unpaid!
#
# No auto-settlement -- payment happens voluntarily via BillingController
# or attempt_settle_outstanding on balance change.
#
# disabled/suspended: skipped entirely (terminal or suspended state)
# Skips companies with zero total (nothing to bill).
# Isolated per company -- one failure doesn't affect others.
#
module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.where(lifecycle_status: :active).find_each(batch_size: COMPANY_PROCESSING_BATCH_SIZE) do |company|
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

      company.flag_unpaid! if company.billing_invoices.where(payment_status: %i[unpaid overdue]).exists?
    end
  end
end
