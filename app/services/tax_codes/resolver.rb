# frozen_string_literal: true

# TaxCodes::Resolver — the single answer to "which tax applies to this item?".
#
# Why it exists: POS, product/service forms, and receipts all need the same
# precedence, and a discarded code must never be reused.
# How it works: prefers the record's kept tax code, then the supplied default,
# then the company's Tax Config default. Returns nil when nothing is available.
# Main associations: reads the record's tax_code and TaxConfig#default_tax_code.
module TaxCodes
  class Resolver
    def self.call(record:, default_tax_code: nil)
      assigned = record.tax_code
      return assigned if assigned && !assigned.discarded?

      fallback = default_tax_code || TaxConfig.for_company!(record.company).default_tax_code
      fallback if fallback && !fallback.discarded?
    end
  end
end
