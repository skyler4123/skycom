# frozen_string_literal: true

# TaxConfig — Atomic purpose: company-wide tax reporting settings (date basis,
# included invoice/purchase/stock-export sources, excluded statuses, branch
# filters).
#
# Why it exists: one persisted configuration per company keeps tax reports
# consistent instead of scattering source/filter defaults.
# How it works: belongs to a company (unique); metadata-backed settings are
# seeded on initialize, and `for_company!` finds or creates the row idempotently.
# Main associations: belongs_to :company (required, unique).
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
    :pos_tax_rate_bp,
    :pos_tax_name
  belongs_to :company

  validates :company_id, uniqueness: true
  validates :pos_tax_rate_bp,
    numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: TAX_RATE_BP_MAX },
    allow_nil: true
  validates :pos_tax_name, length: { maximum: 50 }, allow_blank: true


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
    self.pos_tax_rate_bp = 0 if metadata["pos_tax_rate_bp"].nil?
    self.pos_tax_name = "Tax" if metadata["pos_tax_name"].blank?
  end

  # POS default tax: one company-wide rate, added on top of the discounted
  # subtotal. The rate is stored in basis points so money never touches floats.
  def pos_tax_rate
    pos_tax_rate_bp.to_i / 10_000.0
  end

  def pos_tax_rate_percent
    pos_tax_rate_bp.to_i / 100.0
  end

  def pos_tax?
    pos_tax_rate_bp.to_i.positive?
  end

  def self.for_company!(company)
    find_by(company: company) || begin
      create!(company: company)
    rescue ActiveRecord::RecordNotUnique
      find_by!(company: company)
    end
  end
end
