# frozen_string_literal: true

# WorkflowStep — Atomic purpose: one ordered step in a Workflow (position, name,
# colors, approval rules).
#
# Why it exists: approval chains need explicit ordered steps so a record can move
# forward/backward and leave an audit log at each step.
# How it works: belongs to company and workflow; position is unique within the
# workflow; #next_step/#previous_step navigate by position, and each transition
# writes a WorkflowStepLog.
# Main associations: belongs_to :company, :workflow (required); has_many
# :workflow_step_logs (dependent: :destroy).
class WorkflowStep < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true
  enum :workflow_status, WORKFLOW_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :workflow

  has_many :workflow_step_logs, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 1 },
    uniqueness: { scope: :workflow_id }
  validates :text_color, inclusion: { in: WORKFLOW_STEP_TEXT_COLORS }, allow_blank: true
  validates :background_color, inclusion: { in: WORKFLOW_STEP_BACKGROUND_COLORS }, allow_blank: true

  # --- Methods ---
  def next_step
    workflow.workflow_steps.where("position > ?", position).order(:position).first
  end

  def previous_step
    workflow.workflow_steps.where("position < ?", position).order(:position).last
  end
end
