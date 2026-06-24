# frozen_string_literal: true

module Billing
  class MonthlyBillingJob < ApplicationJob
    queue_as :default

    def perform
      Company.lifecycle_status_active.find_each(batch_size: 50) do |company|
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
