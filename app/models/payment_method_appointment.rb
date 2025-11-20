class PaymentMethodAppointment < ApplicationRecord
  # --- Associations ---
  belongs_to :payment_method
  belongs_to :company

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    pending_approval: 2
  }

  enum :business_type, {
    online: 0,
    in_store: 1,
    recurring: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id, message: "This payment method code is already assigned to this company." }
  validates :status, presence: true
  validates :business_type, presence: true
end