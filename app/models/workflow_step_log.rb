# frozen_string_literal: true

# WorkflowStepLog — Atomic purpose: immutable audit row for one workflow
# transition (submitted, approved, rejected, rework) on a polymorphic subject.
#
# Why it exists: records who acted, from/to which step, and the outcome, so an
# approval history can be reconstructed for purchases, tickets, and other
# workflow-backed records (see docs/PURCHASE_WORKFLOW.md).
# How it works: belongs to company/workflow/workflow_step and an optional
# employee; subject is polymorphic (Purchase, Ticket, ...). from_step_id/
# target_step_id live in metadata.
# Main associations: belongs_to :company, :workflow, :workflow_step (required),
# :subject (polymorphic, required), :employee (optional).
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
