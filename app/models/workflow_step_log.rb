class WorkflowStepLog < ApplicationRecord
  store_accessor :metadata, :from_step_id, :target_step_id

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :outcome, { submitted: 0, approved: 1, rejected: 2, rework: 3 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :workflow
  belongs_to :workflow_step
  belongs_to :employee, optional: true
  belongs_to :subject, polymorphic: true

  # --- Validations ---
  validates :outcome, presence: true
end
