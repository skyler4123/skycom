# frozen_string_literal: true

# CompanyWalletLog — Atomic purpose: immutable before/after audit trail of every
# CompanyWallet balance change.
#
# Why it exists: balance mutations must be explainable; each row stores the balance
# type, amount, and before/after values after the fact.
# How it works: written explicitly by CompanyWallet mutation methods
# (add_to!/deduct_from!/add_credits!) — no callbacks. source is an optional
# polymorphic link to the domain record that caused the change.
# Main associations: belongs_to :company, :company_wallet (required);
# belongs_to :source, polymorphic: true (optional).
class CompanyWalletLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :change_type, { credit: 0, debit: 1, refund: 2, adjustment: 3 }
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed
  # Which wallet balance moved (mirrors CompanyWallet::BALANCES keys).
  enum :balance_type, { main: 0, promo: 1 }, prefix: true
  belongs_to :company
  belongs_to :company_wallet
  belongs_to :source, polymorphic: true, optional: true

  validates :change_amount, :balance_before, :balance_after,
    presence: true, numericality: { only_integer: true }
end
