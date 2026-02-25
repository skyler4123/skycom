class TaskGroup < ApplicationRecord
  include TagConcern

  # --- Associations ---
  belongs_to :company_group
  belongs_to :branch, optional: true
  has_many :task_group_appointments, dependent: :destroy

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  enum :business_type, {
    project_management: 0,
    maintenance_tasks: 1,
    administrative: 2
  }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :code, presence: true, uniqueness: { scope: :company_id }

  validates :business_type, presence: true
end
