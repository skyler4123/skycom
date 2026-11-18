# frozen_string_literal: true

# Task — Atomic purpose: one work item under a TaskGroup, assignable to employees.
#
# Why it exists: operational work needs a trackable unit with status, category,
# and optional branch scoping; grouping and assignment are separate atomic
# tables.
# How it works: belongs to company, optional branch, task_group, category, and
# property mapping; employees join through EmployeeTaskAppointment. Tags and
# dynamic search come from concerns.
# Main associations: belongs_to :task_group, :company, :category,
# :property_mapping (required), :branch (optional); has_many :employees through
# :employee_task_appointments (dependent: :destroy).
class Task < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern

  include TagConcern
  attribute :permission_resource_name, :string, default: -> { self.name }

  enum :country, COUNTRY_CODES, prefix: true, default: :us
  enum :timezone, TIMEZONES, prefix: true, default: :utc

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true
  enum :business_type, {
    general: 0,
    technical: 1,
    administrative: 2
  }
  enum :currency, CURRENCIE_CODES, prefix: true, default: :usd
  # --- Associations ---
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :task_group
  belongs_to :category
  belongs_to :property_mapping
  belongs_to :parent_task, class_name: "Task", optional: true
  belongs_to :project_milestone, optional: true

  has_many :employee_task_appointments, dependent: :destroy
  has_many :employees, through: :employee_task_appointments
  has_many :subtasks, class_name: "Task", foreign_key: :parent_task_id, dependent: :destroy, inverse_of: :parent_task
  has_many :task_dependencies, foreign_key: :predecessor_task_id, dependent: :destroy, inverse_of: :predecessor_task
  has_many :project_time_entries, dependent: :nullify

  # --- Validations ---
  validates :name, presence: true, uniqueness: { scope: :company_id }, length: { maximum: 255 }

  validates :business_type, presence: true
end
