# frozen_string_literal: true

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
