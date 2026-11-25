# frozen_string_literal: true

# TaxCodes::DiscardService — retires a tax code without rewriting history.
#
# Why it exists: a tax code may be referenced by products, services, or the
# company default. Discarding must clear those live references in one place;
# order lines and invoices keep their own rate snapshots.
# How it works: nullifies product/service assignments, clears matching TaxConfig
# defaults, then soft-discards the code.
# Main associations: reads TaxCode#products, #services, and TaxConfig metadata.
module TaxCodes
  class DiscardService
    def self.call(tax_code:)
      TaxCode.transaction do
        tax_code.products.update_all(tax_code_id: nil)
        tax_code.services.update_all(tax_code_id: nil)

        TaxConfig.where(company_id: tax_code.company_id).find_each do |config|
          config.update!(default_tax_code_id: nil) if config.default_tax_code_id == tax_code.id
        end

        tax_code.discard!
      end

      tax_code
    end
  end
end
