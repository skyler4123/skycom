class TaskGroup < ApplicationRecord
  # --- Associations ---
  belongs_to :company_group
  belongs_to :company, optional: true
  has_many :task_group_appointments, dependent: :destroy

  # --- Enums ---
  enum :status, {
    active: 0,
    inactive: 1,
    archived: 2
  }

  enum :business_type, {
    project_management: 0,
    maintenance_tasks: 1,
    administrative: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }
  validates :status, presence: true
  validates :business_type, presence: true
end
