class PaymentMethod < ApplicationRecord
  # --- Associations ---
  # This model is intended to be global, so it does not belong to a company.
  has_many :payment_method_appointments, dependent: :destroy
  has_many :companies, through: :payment_method_appointments

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    online: 0,
    offline: 1,
    global: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: true
  validates :business_type, presence: true
end
