# frozen_string_literal: true

# ProductionOrderOperation — Atomic purpose: the executable instance of one routing operation on one production order, with its actual time and output.
#
# Why it exists: operators start and pause jobs, and labour cost comes from the minutes actually spent versus the standard; that comparison is only possible if each step of each order has its own row.
# How it works: child of the order, linked to the routing template and the machine actually used. `logged_minutes` and `produced_quantity` are the floor's data; `started_at`/`completed_at` are the evidence. Status is the shared workflow enum so a paused job is explicit.
# Main associations: belongs_to :company, :production_order, :production_operation, :work_center (optional), :employee (optional).
class ProductionOrderOperation < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :pending

  # --- Associations ---
  belongs_to :company
  belongs_to :production_order
  belongs_to :production_operation
  belongs_to :work_center, optional: true
  belongs_to :employee, optional: true

  # --- Validations ---
  validates :logged_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
