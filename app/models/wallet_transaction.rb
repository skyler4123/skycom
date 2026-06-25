# frozen_string_literal: true

# Audit trail for every wallet balance change. Records before/after snapshots
# of both promo_balance and main_balance so the full history is reconstructable.
#
# Created by Billing::SettlementService during monthly billing:
#   WalletTransaction.create!(
#     company: company,
#     billing_invoice: invoice,
#     transaction_type: :deduction,
#     amount_cents: total,
#     balance_before_cents: 1000,    # main_balance before
#     balance_after_cents: 500,      # main_balance after
#     promo_balance_before_cents: 0,
#     promo_balance_after_cents: 0,
#     description: "Monthly billing invoice INV-202606-A1B2C3"
#   )
#
# Types: top_up (0), deduction (1), refund (2), promo_credit (3)
#
class WalletTransaction < ApplicationRecord
  belongs_to :company
  belongs_to :billing_invoice, optional: true

  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_type, presence: true

  enum :transaction_type, {
    top_up: 0,
    deduction: 1,
    refund: 2,
    promo_credit: 3
  }
end
