class Project < ApplicationRecord
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
  belongs_to :project_group
  belongs_to :category
  belongs_to :property_mapping

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    internal: 0,
    client_project: 1,
    maintenance: 2
  }

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }

  validates :business_type, presence: true
end
