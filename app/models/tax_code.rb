# frozen_string_literal: true

# TaxCode — Atomic purpose: one named tax rate (VAT, GST, sales tax, withholding) with the account it settles to.
#
# Why it exists: tax is per line, per jurisdiction and per effective date, and a company must be able to calculate it instead of typing an amount. Storing rate + kind + jurisdiction + account here is what lets an invoice line carry a tax code and the posting rule derive the tax journal line without any hardcoded percentage.
# How it works: rate is basis points (1000 = 10.00%) so no float ever touches money. `is_inclusive` distinguishes tax-included pricing (common in VN/EU retail) from tax-added pricing. Codes are soft-discarded with Discard::Model; discarded codes stay on historical snapshots but are no longer selectable.
# Main associations: belongs_to :company, :ledger_account (optional); has_many :products, :services.
class TaxCode < ApplicationRecord
  include Discard::Model

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :kind, TAX_CODE_KINDS, prefix: true, default: :vat

  # --- Associations ---
  belongs_to :company
  belongs_to :ledger_account, optional: true
  has_many :products, dependent: :nullify
  has_many :services, dependent: :nullify

  # --- Scopes ---
  scope :ordered, -> { order(:name, :code) }
  scope :available, -> { kept }
  scope :active_on, ->(date = Date.current) {
    where("effective_from IS NULL OR effective_from <= ?", date)
      .where("effective_to IS NULL OR effective_to >= ?", date)
  }

  # --- Validations ---
  validates :code, presence: true, length: { maximum: 32 }, uniqueness: { scope: :company_id }
  validates :name, presence: true, length: { maximum: 255 }
  validates :kind, presence: true
  validates :rate_bp, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: TAX_RATE_BP_MAX }

  # --- Callbacks ---
  before_validation :normalize_code

  # --- Methods ---
  def rate
    rate_bp.to_i / 10_000.0
  end

  def rate_percent
    rate_bp.to_i / 100.0
  end

  # Shared option shape for product/service pickers, POS payloads, and receipts.
  def option_payload
    {
      id: id,
      code: code,
      name: name,
      rate_bp: rate_bp.to_i,
      rate_percent: rate_percent,
      kind: kind,
      inclusive: is_inclusive
    }
  end

  def tax_for_cents(net_cents)
    (net_cents.to_i * rate_bp.to_i / 10_000.0).round
  end

  # Splits a gross line amount into taxable and tax cents. Inclusive codes
  # extract tax from the gross; exclusive codes add tax on top of it.
  def breakdown_for(gross_cents)
    gross = gross_cents.to_i

    if is_inclusive?
      tax = ((gross * rate_bp).to_r / (10_000 + rate_bp)).round
      { taxable_cents: gross - tax, tax_cents: tax }
    else
      tax = ((gross * rate_bp).to_r / 10_000).round
      { taxable_cents: gross, tax_cents: tax }
    end
  end

  private

  def normalize_code
    if code.present?
      self.code = code.to_s.strip.upcase
    elsif new_record?
      base = name.to_s.parameterize(separator: "_").upcase.first(28).presence || "TAX"
      candidate = base
      suffix = 2
      while company && company.tax_codes.where(code: candidate).where.not(id: id).exists?
        candidate = "#{base}_#{suffix}"
        suffix += 1
      end
      self.code = candidate
    end
  end
end
