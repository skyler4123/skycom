class PaymentMethod < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  # This model is intended to be global, so it does not belong to a branch.
  has_many :payment_method_appointments, dependent: :destroy
  has_many :branches, through: :payment_method_appointments

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

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
