class FacilityGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company
  has_many :facility_group_appointments, dependent: :destroy
  has_many :facilities, through: :facility_group_appointments, source: :appoint_to, source_type: "Facility"

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    under_maintenance: 2
  }

  enum :business_type, {
    building: 0,
    floor: 1,
    wing: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end