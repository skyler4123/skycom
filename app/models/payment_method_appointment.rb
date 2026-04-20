class PaymentMethodAppointment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :payment_method
  belongs_to :company
  belongs_to :branch, optional: true

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    online: 0,
    in_store: 1,
    recurring: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id, message: "This payment method code is already assigned to this company group." }

  validates :business_type, presence: true
end
