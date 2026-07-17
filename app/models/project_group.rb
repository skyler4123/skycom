class ProjectGroup < ApplicationRecord
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
  has_many :project_group_appointments, dependent: :destroy

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    internal: 0,
    client_facing: 1,
    research_and_development: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :branch_id }

  validates :business_type, presence: true
end
