class Project < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  belongs_to :project_group

  # --- Enums ---
  enum :status, {
    planning: 0,
    in_progress: 1,
    completed: 2,
    on_hold: 3,
    cancelled: 4
  }

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
