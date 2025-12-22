class Booking < ApplicationRecord
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :appoint_from, polymorphic: true, optional: true
  belongs_to :appoint_to, polymorphic: true

  has_one :period_appointment, as: :appoint_to, dependent: :destroy
  has_one :period, through: :period_appointment

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    internal_meeting: 0,
    client_session: 1,
    resource_allocation: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end
