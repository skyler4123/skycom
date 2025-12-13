class Payment < ApplicationRecord
  # --- Associations ---
  belongs_to :invoice

  # --- Enums ---
  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2,
    refunded: 3
  }

  enum :payment_method, {
    credit_card: 0,
    bank_transfer: 1,
    paypal: 2,
    cash: 3
  }

  enum :business_type, {
    standard_payment: 0,
    prepayment: 1,
    final_payment: 2
  }

  # --- Validations ---
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :payment_method, presence: true
  validates :status, presence: true
end
