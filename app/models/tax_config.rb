# frozen_string_literal: true

# TaxConfig — Atomic purpose: company-wide tax reporting settings (date basis,
# included invoice/purchase/stock-export sources, excluded statuses, branch
# filters) plus the default tax code used when a product/service has none.
#
# Why it exists: one persisted configuration per company keeps tax reports and
# the default tax rate consistent instead of scattering source/filter defaults.
# How it works: belongs to a company (unique); metadata-backed settings are
# seeded on initialize, and `for_company!` finds or creates the row idempotently.
# Main associations: belongs_to :company (required, unique); the default tax
# code is a metadata-backed pointer resolved through #default_tax_code.
class TaxConfig < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  store_accessor :metadata,
    :date_basis,
    :include_invoices,
    :include_purchases,
    :include_stock_exports,
    :excluded_invoice_statuses,
    :excluded_purchase_statuses,
    :stock_export_business_types,
    :branch_ids,
    :default_tax_code_id
  belongs_to :company

  validates :company_id, uniqueness: true
  validate :default_tax_code_belongs_to_company

  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.metadata = {} if metadata.blank?
    self.date_basis = "created_at" if date_basis.blank?
    self.include_invoices = true if include_invoices.nil?
    self.include_purchases = true if include_purchases.nil?
    self.include_stock_exports = true if include_stock_exports.nil?
    self.excluded_invoice_statuses = [] if excluded_invoice_statuses.nil?
    self.excluded_purchase_statuses = [] if excluded_purchase_statuses.nil?
    self.stock_export_business_types = [ "sale" ] if stock_export_business_types.nil?
    self.branch_ids = [] if branch_ids.nil?
  end

  # The default is a pointer, never a copied rate. Discarded codes are ignored
  # so a sale cannot silently use a retired code. This stays a method because
  # the foreign key lives in metadata, not in a column.
  def default_tax_code
    return nil if default_tax_code_id.blank?

    company&.tax_codes&.kept&.find_by(id: default_tax_code_id)
  end

  def default_tax_code=(code)
    self.default_tax_code_id = code&.id
  end

  def self.for_company!(company)
    find_by(company: company) || begin
      create!(company: company)
    rescue ActiveRecord::RecordNotUnique
      find_by!(company: company)
    end
  end

  private

  def default_tax_code_belongs_to_company
    return if default_tax_code_id.blank?

    code = TaxCode.kept.find_by(id: default_tax_code_id)
    return if code && code.company_id == company_id

    errors.add(:default_tax_code, "must be an available tax code for this company")
  end
end
