# frozen_string_literal: true

# TaxCode — Atomic purpose: one named tax rate (VAT, GST, sales tax, withholding) with the account it settles to.
#
# Why it exists: tax is per line, per jurisdiction and per effective date, and a company must be able to calculate it instead of typing an amount. Storing rate + kind + jurisdiction + account here is what lets an invoice line carry a tax code and the posting rule derive the tax journal line without any hardcoded percentage.
# How it works: rate is basis points (1000 = 10.00%) so no float ever touches money. Effective dates make historic documents reproducible when a rate changes. `is_inclusive` distinguishes tax-included pricing (common in VN/EU retail) from tax-added pricing. Referenced from invoice/purchase lines and journal lines.
# Main associations: belongs_to :company, :ledger_account (optional).
class TaxCode < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :kind, TAX_CODE_KINDS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :ledger_account, optional: true

  # --- Scopes ---
  scope :ordered, -> { order(:code) }
  scope :active_on, ->(date = Date.current) {
    where("effective_from IS NULL OR effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 255 }
  validates :rate_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000 }

  # --- Methods ---
  def rate
    rate_bp.to_i / 10_000.0
  end

  def tax_for_cents(net_cents)
    (net_cents.to_i * rate_bp.to_i / 10_000.0).round
  end
end
