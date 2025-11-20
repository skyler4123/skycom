class Booking < ApplicationRecord
  belongs_to :company
  belongs_to :appoint_from, polymorphic: true
  belongs_to :appoint_to, polymorphic: true

  has_one :period_appointment, as: :appoint_to, dependent: :destroy
  has_one :period, through: :period_appointment

  # --- Enums ---
  enum :status, {
    confirmed: 0,
    pending: 1,
    cancelled: 2,
    completed: 3
  }

  enum :business_type, {
    internal_meeting: 0,
    client_session: 1,
    resource_allocation: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end
