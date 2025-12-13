class ProjectGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :project_group_appointments, dependent: :destroy

  # --- Enums ---
  enum :status, {
    active: 0,
    on_hold: 1,
    completed: 2,
    archived: 3
  }

  enum :business_type, {
    internal: 0,
    client_facing: 1,
    research_and_development: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end
