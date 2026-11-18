# frozen_string_literal: true

# ExchangeRate — Atomic purpose: one dated conversion rate between two currencies, optionally scoped to a company.
#
# Why it exists: multi-currency reporting needs a frozen rate per date: revaluing an AR balance at today's rate and the invoice at yesterday's rate is what produces realised and unrealised FX gain/loss, and without a stored rate those numbers cannot be reproduced or audited.
# How it works: append rows per (base, quote, effective_on); the latest row on or before a date is the rate. `company_id` is nullable — nil means a platform-wide default, a company row overrides it. Journal lines snapshot the chosen rate in `fx_rate`, so this table can grow without rewriting posted history.
# Main associations: belongs_to :company (optional). No outgoing associations; read by Ledger posting and revaluation jobs.
class ExchangeRate < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :base_currency, CURRENCIE_CODES, prefix: true
  enum :quote_currency, CURRENCIE_CODES, prefix: true

  # --- Associations ---
  belongs_to :company, optional: true

  # --- Scopes ---
  scope :for_pair, ->(base, quote) { where(base_currency: base, quote_currency: quote) }
  scope :on_or_before, ->(date) { where(effective_on: ..date) }
  scope :latest_first, -> { order(effective_on: :desc) }

  # --- Validations ---
  validates :rate, numericality: { greater_than: 0 }
  validates :effective_on, presence: true
  validate :currencies_differ

  # --- Methods ---
  def self.rate_for(base:, quote:, on: Date.current, company: nil)
    scope = company.present? ? where(company_id: [ nil, company.id ]) : where(company_id: nil)
    scope.for_pair(base, quote).where(effective_on: ..on)
      .order(company_id: :desc, effective_on: :desc).first&.rate
  end

  private

  def currencies_differ
    return if base_currency.blank? || base_currency != quote_currency

    errors.add(:quote_currency, "must differ from the base currency")
  end
end
