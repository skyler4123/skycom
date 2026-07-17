class FacilityGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd

  include TagConcern

  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
  has_many :facility_group_appointments, dependent: :destroy
  has_many :facilities, through: :facility_group_appointments, source: :appoint_to, source_type: "Facility"

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    building: 0,
    floor: 1,
    wing: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
