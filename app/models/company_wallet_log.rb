# frozen_string_literal: true

# CompanyWalletLog — Atomic purpose: immutable before/after audit trail of
# every CompanyWallet balance change. Written explicitly by CompanyWallet
# mutation methods (add_credits!/deduct_credits!) — no callbacks.
class CompanyWalletLog < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  belongs_to :company
  belongs_to :company_wallet
  belongs_to :source, polymorphic: true, optional: true

  enum :change_type, { credit: 0, debit: 1, refund: 2, adjustment: 3 }

  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true, default: :active
  enum :workflow_status, WORKFLOW_STATUS, prefix: true, default: :confirmed

  validates :change_amount, :balance_before, :balance_after,
    presence: true, numericality: { only_integer: true }
end
