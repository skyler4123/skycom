class FacilityGroup < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :facility_group_appointments, dependent: :destroy
  has_many :facilities, through: :facility_group_appointments, source: :appoint_to, source_type: "Facility"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    building: 0,
    floor: 1,
    wing: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validates :business_type, presence: true
end
