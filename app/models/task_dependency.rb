# frozen_string_literal: true

# TaskDependency — Atomic purpose: one scheduling link between two tasks (predecessor → successor) with its type and lag.
#
# Why it exists: a Gantt chart and a critical path are only the visible output of a precedence graph; without stored dependencies the plan is a list of dates that cannot be rescheduled when one task slips.
# How it works: explicit predecessor/successor pair with a dependency type (finish-to-start and the three variants) and a lag in days. Self-links are blocked and the same pair cannot be declared twice, which keeps the graph acyclic at the first level.
# Main associations: belongs_to :company, :predecessor_task, :successor_task (both Task).
class TaskDependency < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :dependency_type, TASK_DEPENDENCY_TYPES, prefix: true, default: :finish_to_start

  # --- Associations ---
  belongs_to :company
  belongs_to :predecessor_task, class_name: "Task"
  belongs_to :successor_task, class_name: "Task"

  # --- Validations ---
  validates :predecessor_task_id, uniqueness: { scope: :successor_task_id }
  validate :tasks_differ

  private

  def tasks_differ
    return if predecessor_task_id.blank? || predecessor_task_id != successor_task_id

    errors.add(:successor_task, "cannot depend on itself")
  end
end
