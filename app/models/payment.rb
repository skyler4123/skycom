class Payment < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :branch, optional: true
  belongs_to :invoice

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

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
  validates :currency_code, presence: true
  validates :payment_method, presence: true
end
