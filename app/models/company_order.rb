# frozen_string_literal: true

# CompanyOrder — Atomic purpose: capture the credit-purchase deal (money tier
# → credits) with a rate snapshot. The order's state changes ONLY through the
# chain: when its CompanyInvoice becomes paid, the invoice calls #complete!,
# which credits the company wallet. Order never mutates the wallet directly
# outside that path.
class CompanyOrder < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :pending
  belongs_to :company
  belongs_to :user
  has_one :company_invoice, dependent: :destroy

  validates :money_amount_cents, :credit_amount,
    presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :rate_tier_must_exist

  # Credits delivered per cent of money paid (derived rate snapshot).
  def credits_per_cent
    money_amount_cents.to_i.zero? ? 0 : credit_amount / money_amount_cents
  end

  # Called by CompanyInvoice#complete_order_if_paid! — idempotent.
  def complete!
    return if %w[completed cancelled failed].include?(workflow_status)

    transaction do
      wallet = company.company_wallet
      wallet.update!(walletable: self)
      wallet.add_credits!(amount: credit_amount, source: self, description: "Credits purchased via order #{id}")
      update!(workflow_status: :completed)
    end
  end

  private

  def rate_tier_must_exist
    return unless company.present? && money_amount_cents.present?

    rates = CREDIT_RATES[company.country.to_sym]
    unless rates&.key?(money_amount_cents)
      errors.add(:money_amount_cents, "is not an available credit rate tier")
      return
    end

    expected = rates[money_amount_cents]
    if credit_amount != expected
      errors.add(:credit_amount, "does not match the rate tier (#{expected} credits expected)")
    end
  end
end
