class Project < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :project_group

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    internal: 0,
    client_project: 1,
    maintenance: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }

  validates :business_type, presence: true
end
