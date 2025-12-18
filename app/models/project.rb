class Project < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :project_group

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS
  enum :workflow_status, WORKFLOW_STATUS

  enum :business_type, {
    internal: 0,
    client_project: 1,
    maintenance: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :status, presence: true
  validates :business_type, presence: true
end
