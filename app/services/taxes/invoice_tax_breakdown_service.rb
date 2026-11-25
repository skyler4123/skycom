# frozen_string_literal: true

# Taxes::InvoiceTaxBreakdownService — groups invoice tax snapshots by code.
#
# Why it exists: with mixed rates the invoice total alone cannot tell an
# accountant how much tax came from each rate.
# How it works: reads each invoice's metadata `tax_breakdown` array and sums
# taxable/tax cents by name, rate, and inclusive/exclusive treatment. Invoices
# without a breakdown (legacy) contribute nothing.
# Main associations: reads Invoice#tax_breakdown.
module Taxes
  class InvoiceTaxBreakdownService
    def self.call(invoices:)
      new(invoices: invoices).call
    end

    def initialize(invoices:)
      @invoices = invoices
    end

    def call
      rows = {}

      @invoices.find_each do |invoice|
        Array(invoice.tax_breakdown).each do |line|
          name = line["name"].presence || "Tax"
          rate_bp = line["rate_bp"].to_i
          inclusive = line["inclusive"] == true || line["inclusive"] == "true"
          key = [ name, rate_bp, inclusive ]

          row = rows[key] ||= {
            name: name,
            rate_bp: rate_bp,
            rate_percent: rate_bp / 100.0,
            inclusive: inclusive,
            taxable_cents: 0,
            tax_cents: 0
          }
          row[:taxable_cents] += line["taxable_cents"].to_i
          row[:tax_cents] += line["tax_cents"].to_i
        end
      end

      rows.values.sort_by { |row| [ row[:name].to_s, row[:rate_bp], row[:inclusive] ? 1 : 0 ] }
    end
  end
end
